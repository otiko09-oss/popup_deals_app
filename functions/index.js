/**
 * Popup Deals — Stripe subscription backend.
 *
 * Two entry points:
 *  1. createCheckoutSession (callable) — the Flutter app calls this to get a
 *     Stripe Checkout URL for a given business + plan.
 *  2. stripeWebhook (HTTPS) — Stripe calls this on subscription lifecycle
 *     events; it keeps Firestore's `subscriptions/{businessId}` doc in sync.
 *
 * SETUP (you must do this — Claude cannot create your Stripe account):
 *   1. Create a Stripe account at https://dashboard.stripe.com
 *   2. Create 3 recurring Products/Prices (Starter/Growth/Premium) matching
 *      the ids in lib/core/constants/subscription_plans.dart
 *   3. Set config:
 *      firebase functions:config:set stripe.secret="sk_live_or_test_..." \
 *                                     stripe.webhook_secret="whsec_..." \
 *                                     stripe.price_starter="price_..." \
 *                                     stripe.price_growth="price_..." \
 *                                     stripe.price_premium="price_..."
 *   4. Deploy: cd functions && npm install && npm run deploy
 *   5. In the Stripe Dashboard, add a webhook endpoint pointing at the
 *      deployed stripeWebhook URL, listening for:
 *        checkout.session.completed
 *        customer.subscription.updated
 *        customer.subscription.deleted
 */

const functions = require("firebase-functions");
const admin = require("firebase-admin");
const Stripe = require("stripe");

admin.initializeApp();
const db = admin.firestore();

const cfg = functions.config().stripe || {};
const stripe = Stripe(cfg.secret || process.env.STRIPE_SECRET || "");

const PRICE_IDS = {
  starter: cfg.price_starter || process.env.STRIPE_PRICE_STARTER,
  growth: cfg.price_growth || process.env.STRIPE_PRICE_GROWTH,
  premium: cfg.price_premium || process.env.STRIPE_PRICE_PREMIUM,
};

function requireAuthenticated(context) {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "You must be signed in to perform this action."
    );
  }
  return context.auth.uid;
}

async function canActForBusiness(uid, businessId, transaction) {
  if (uid === businessId) return true;
  const staffRef = db.collection("business_staff").doc(uid);
  const staff = transaction ? await transaction.get(staffRef) : await staffRef.get();
  return staff.exists && staff.data().businessId === businessId &&
    staff.data().isActive === true;
}

async function ensureNotBlocked(uid) {
  const user = await db.collection("users").doc(uid).get();
  if (user.exists && user.data().isBlocked === true) {
    throw new functions.https.HttpsError("permission-denied", "This account is blocked.");
  }
}

async function notifyUser(uid, title, body, data = {}) {
  const user = await db.collection("users").doc(uid).get();
  const tokens = user.exists && Array.isArray(user.data().fcmTokens)
    ? user.data().fcmTokens.filter(token => typeof token === "string" && token)
    : [];
  if (tokens.length === 0) return;
  try {
    const response = await admin.messaging().sendEachForMulticast({
      tokens,
      notification: { title, body },
      data: Object.fromEntries(Object.entries(data).map(([key, value]) => [key, String(value)])),
    });
    const invalidTokens = response.responses
      .map((result, index) => !result.success ? tokens[index] : null)
      .filter(Boolean);
    if (invalidTokens.length) {
      await user.ref.update({ fcmTokens: admin.firestore.FieldValue.arrayRemove(...invalidTokens) });
    }
  } catch (error) {
    // Notifications must never make a paid order or redemption fail.
    functions.logger.warn("Unable to send notification", error);
  }
}

/**
 * Callable from the Flutter app:
 *   FirebaseFunctions.instance.httpsCallable('createCheckoutSession')
 *     .call({ businessId, planId, successUrl, cancelUrl });
 * Returns { url } — open it with url_launcher.
 */
exports.createCheckoutSession = functions.https.onCall(async (data, context) => {
  const uid = requireAuthenticated(context);
  await ensureNotBlocked(uid);

  const { businessId, planId, successUrl, cancelUrl } = data;
  if (!businessId || !planId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "businessId and planId are required."
    );
  }

  // A checkout can only ever change the caller's own business subscription.
  // Never trust a business id sent from a mobile client.
  if (businessId !== uid) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "You can only manage your own business subscription."
    );
  }

  const businessSnap = await db.collection("businesses").doc(businessId).get();
  if (!businessSnap.exists) {
    throw new functions.https.HttpsError("failed-precondition", "Business profile not found.");
  }

  const priceId = PRICE_IDS[planId];
  if (!priceId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      `Unknown planId '${planId}'. Configure its Stripe price id first.`
    );
  }

  // Reuse an existing Stripe customer for this business if we have one.
  const subRef = db.collection("subscriptions").doc(businessId);
  const subSnap = await subRef.get();
  let customerId = subSnap.exists ? subSnap.data().stripeCustomerId : null;

  if (!customerId) {
    const business = businessSnap.exists ? businessSnap.data() : {};
    const customer = await stripe.customers.create({
      metadata: { businessId, uid: context.auth.uid },
      email: business.email || context.auth.token.email || undefined,
      name: business.name || undefined,
    });
    customerId = customer.id;
  }

  const session = await stripe.checkout.sessions.create({
    mode: "subscription",
    customer: customerId,
    line_items: [{ price: priceId, quantity: 1 }],
    // Do not accept arbitrary redirect URLs from a client.
    success_url: "https://popupdeals.app/subscription/success",
    cancel_url: "https://popupdeals.app/subscription/cancel",
    metadata: { businessId, planId },
    subscription_data: { metadata: { businessId, planId } },
  });

  // Mark as pending immediately so the UI can reflect "processing".
  await subRef.set(
    {
      businessId,
      planId,
      status: "pending",
      stripeCustomerId: customerId,
      updatedAt: new Date().toISOString(),
    },
    { merge: true }
  );

  return { url: session.url };
});

/** Creates an order and its one-time QR redemption from server-verified data. */
exports.createReservation = functions.https.onCall(async (data, context) => {
  const uid = requireAuthenticated(context);
  await ensureNotBlocked(uid);
  const { dealId, quantity = 1, notes } = data || {};
  if (typeof dealId !== "string" || !dealId || !Number.isInteger(quantity) || quantity < 1 || quantity > 20) {
    throw new functions.https.HttpsError("invalid-argument", "A valid deal and quantity are required.");
  }

  const dealSnap = await db.collection("deals").doc(dealId).get();
  if (!dealSnap.exists) throw new functions.https.HttpsError("not-found", "Deal not found.");
  const deal = dealSnap.data();
  const now = new Date().toISOString();
  const expiresAt = deal.expiresAt && (typeof deal.expiresAt.toDate === "function"
    ? deal.expiresAt.toDate() : new Date(deal.expiresAt));
  if (deal.isActive !== true || deal.moderationStatus !== "approved" || (expiresAt && expiresAt <= new Date())) {
    throw new functions.https.HttpsError("failed-precondition", "This deal is no longer available.");
  }

  const businessId = deal.restaurantId;
  const businessSnap = await db.collection("businesses").doc(businessId).get();
  if (!businessSnap.exists) throw new functions.https.HttpsError("failed-precondition", "Business not found.");
  const business = businessSnap.data();
  const userSnap = await db.collection("users").doc(uid).get();
  const user = userSnap.exists ? userSnap.data() : {};
  const orderRef = db.collection("orders").doc();
  const redemptionRef = db.collection("redemptions").doc();
  const redemptionExpiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString();
  const qrPayload = `popupdeals://redeem/${redemptionRef.id}`;

  const order = {
    id: orderRef.id, userId: uid, dealId, businessId, status: "pending", createdAt: now,
    dealTitle: deal.title || "", dealPrice: Number(deal.discountedPrice || 0), dealImage: deal.imageUrl || "",
    userName: user.displayName || context.auth.token.name || "", userPhone: user.phoneNumber || "",
    businessName: business.name || deal.restaurant || "", businessLatitude: Number(business.latitude || deal.latitude || 0),
    businessLongitude: Number(business.longitude || deal.longitude || 0), quantity,
    ...(typeof notes === "string" && notes.trim() ? { notes: notes.trim().slice(0, 500) } : {}),
    redemptionId: redemptionRef.id, qrPayload,
  };
  const redemption = {
    id: redemptionRef.id, orderId: orderRef.id, dealId, userId: uid, businessId, qrPayload,
    status: "pending", createdAt: now, expiresAt: redemptionExpiresAt,
    dealTitle: deal.title || "", businessName: business.name || deal.restaurant || "",
  };
  const batch = db.batch();
  batch.set(orderRef, order);
  batch.set(redemptionRef, redemption);
  await batch.commit();
  await notifyUser(
    businessId,
    "New reservation",
    `${user.displayName || "A customer"} claimed ${deal.title || "a deal"}.`,
    { type: "reservation_created", orderId: orderRef.id }
  );
  return { orderId: orderRef.id, redemption: serializeTimestamps(redemption) };
});

/** Updates the order state with server-enforced role and state-transition checks. */
exports.updateOrderStatus = functions.https.onCall(async (data, context) => {
  const uid = requireAuthenticated(context);
  await ensureNotBlocked(uid);
  const { orderId, status } = data || {};
  if (typeof orderId !== "string" || !["accepted", "ready", "completed", "cancelled"].includes(status)) {
    throw new functions.https.HttpsError("invalid-argument", "Invalid order update.");
  }
  const orderRef = db.collection("orders").doc(orderId);
  const notification = await db.runTransaction(async tx => {
    const snap = await tx.get(orderRef);
    if (!snap.exists) throw new functions.https.HttpsError("not-found", "Order not found.");
    const order = snap.data();
    if (!await canActForBusiness(uid, order.businessId, tx)) {
      throw new functions.https.HttpsError("permission-denied", "You cannot manage this order.");
    }
    const permitted = { pending: ["accepted", "cancelled"], accepted: ["ready", "cancelled"], ready: ["completed", "cancelled"] };
    if (!(permitted[order.status] || []).includes(status)) {
      throw new functions.https.HttpsError("failed-precondition", "Invalid order status transition.");
    }
    const timestamp = new Date().toISOString();
    const update = { status, updatedAt: timestamp };
    if (status === "accepted") update.acceptedAt = timestamp;
    if (status === "ready") update.readyAt = timestamp;
    if (status === "completed") {
      update.completedAt = timestamp;
      // A manually completed order can no longer be redeemed by its QR code.
      if (typeof order.redemptionId === "string" && order.redemptionId) {
        tx.update(db.collection("redemptions").doc(order.redemptionId), { status: "cancelled" });
      }
    }
    tx.update(orderRef, update);
    return { userId: order.userId, dealTitle: order.dealTitle || "your reservation" };
  });
  await notifyUser(
    notification.userId,
    "Reservation update",
    `${notification.dealTitle} is now ${status}.`,
    { type: "order_status", orderId, status }
  );
  return { ok: true };
});

/** Redeems a QR code exactly once; all linked writes happen atomically. */
exports.redeemReservation = functions.https.onCall(async (data, context) => {
  const uid = requireAuthenticated(context);
  await ensureNotBlocked(uid);
  const { redemptionId } = data || {};
  if (typeof redemptionId !== "string" || !redemptionId) {
    throw new functions.https.HttpsError("invalid-argument", "A redemption id is required.");
  }
  const redemptionRef = db.collection("redemptions").doc(redemptionId);
  const result = await db.runTransaction(async tx => {
    const snap = await tx.get(redemptionRef);
    if (!snap.exists) throw new functions.https.HttpsError("not-found", "Redemption not found.");
    const redemption = snap.data();
    if (!await canActForBusiness(uid, redemption.businessId, tx)) {
      throw new functions.https.HttpsError("permission-denied", "This redemption belongs to another business.");
    }
    const now = new Date().toISOString();
    if (redemption.status !== "pending") throw new functions.https.HttpsError("failed-precondition", "This QR code has already been used.");
    const expiresAt = typeof redemption.expiresAt.toDate === "function"
      ? redemption.expiresAt.toDate() : new Date(redemption.expiresAt);
    if (expiresAt <= new Date(now)) {
      tx.update(redemptionRef, { status: "expired" });
      throw new functions.https.HttpsError("failed-precondition", "This QR code has expired.");
    }
    tx.update(redemptionRef, { status: "redeemed", redeemedAt: now });
    tx.update(db.collection("deals").doc(redemption.dealId), { redeemed: admin.firestore.FieldValue.increment(1) });
    tx.update(db.collection("orders").doc(redemption.orderId), { status: "completed", completedAt: now, updatedAt: now });
    return { ...redemption, status: "redeemed", redeemedAt: now };
  });
  await notifyUser(
    result.userId,
    "Deal redeemed",
    `${result.dealTitle || "Your deal"} has been redeemed.`,
    { type: "redemption_completed", redemptionId }
  );
  return { redemption: serializeTimestamps(result) };
});

function serializeTimestamps(value) {
  return Object.fromEntries(Object.entries(value).map(([key, item]) => [
    key, item && typeof item.toDate === "function" ? item.toDate().toISOString() : item,
  ]));
}

/**
 * Stripe webhook — deploy URL goes into the Stripe Dashboard.
 * Keeps subscriptions/{businessId} and businesses/{businessId} in sync
 * with what actually happened on Stripe's side (source of truth).
 */
exports.stripeWebhook = functions.https.onRequest(async (req, res) => {
  const sig = req.headers["stripe-signature"];
  const webhookSecret = cfg.webhook_secret || process.env.STRIPE_WEBHOOK_SECRET;

  let event;
  try {
    event = stripe.webhooks.constructEvent(req.rawBody, sig, webhookSecret);
  } catch (err) {
    functions.logger.error("Webhook signature verification failed", err);
    res.status(400).send(`Webhook Error: ${err.message}`);
    return;
  }

  try {
    switch (event.type) {
      case "checkout.session.completed": {
        const session = event.data.object;
        const businessId = session.metadata && session.metadata.businessId;
        const planId = session.metadata && session.metadata.planId;
        if (businessId) {
          await db.collection("subscriptions").doc(businessId).set(
            {
              businessId,
              planId,
              status: "active",
              stripeCustomerId: session.customer,
              stripeSubscriptionId: session.subscription,
              startedAt: new Date().toISOString(),
              updatedAt: new Date().toISOString(),
            },
            { merge: true }
          );
          await syncBusinessLimits(businessId, planId, "active");
        }
        break;
      }

      case "customer.subscription.updated": {
        const sub = event.data.object;
        const businessId = sub.metadata && sub.metadata.businessId;
        if (businessId) {
          const status = sub.status === "active" ? "active" : sub.status;
          await db.collection("subscriptions").doc(businessId).set(
            {
              status,
              expiresAt: sub.current_period_end
                ? new Date(sub.current_period_end * 1000).toISOString()
                : null,
              updatedAt: new Date().toISOString(),
            },
            { merge: true }
          );
          await syncBusinessLimits(businessId, sub.metadata.planId, status);
        }
        break;
      }

      case "customer.subscription.deleted": {
        const sub = event.data.object;
        const businessId = sub.metadata && sub.metadata.businessId;
        if (businessId) {
          await db.collection("subscriptions").doc(businessId).set(
            { status: "cancelled", updatedAt: new Date().toISOString() },
            { merge: true }
          );
          await syncBusinessLimits(businessId, "starter", "cancelled");
        }
        break;
      }

      default:
        functions.logger.info(`Unhandled Stripe event type: ${event.type}`);
    }

    res.status(200).send({ received: true });
  } catch (err) {
    functions.logger.error("Error handling Stripe webhook", err);
    res.status(500).send("Internal error");
  }
});

/** Mirrors plan limits onto the business doc so client reads stay simple. */
async function syncBusinessLimits(businessId, planId, status) {
  const plans = {
    starter: { maxActiveDeals: 3 },
    growth: { maxActiveDeals: 10 },
    premium: { maxActiveDeals: 25 },
  };
  const plan = plans[planId] || plans.starter;
  await db.collection("businesses").doc(businessId).set(
    {
      subscriptionPlanId: planId || "starter",
      subscriptionStatus: status,
      maxActiveDeals: plan.maxActiveDeals,
      updatedAt: new Date().toISOString(),
    },
    { merge: true }
  );
}
