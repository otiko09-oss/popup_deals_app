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

/**
 * Callable from the Flutter app:
 *   FirebaseFunctions.instance.httpsCallable('createCheckoutSession')
 *     .call({ businessId, planId, successUrl, cancelUrl });
 * Returns { url } — open it with url_launcher.
 */
exports.createCheckoutSession = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "You must be signed in to subscribe."
    );
  }

  const { businessId, planId, successUrl, cancelUrl } = data;
  if (!businessId || !planId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "businessId and planId are required."
    );
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
    const businessSnap = await db.collection("businesses").doc(businessId).get();
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
    success_url: successUrl || "https://popupdeals.app/subscription/success",
    cancel_url: cancelUrl || "https://popupdeals.app/subscription/cancel",
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
