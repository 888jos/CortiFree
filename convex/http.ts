import { httpRouter } from "convex/server";
import { auth } from "./auth";
import { revenueCatWebhook } from "./subscriptions";

const http = httpRouter();

// Serves /.well-known/openid-configuration and /.well-known/jwks.json, which
// Convex uses to verify the access tokens returned by `auth:signIn`.
auth.addHttpRoutes(http);

// RevenueCat → server-verified entitlement (subscriptions.ts).
http.route({ path: "/revenuecat/webhook", method: "POST", handler: revenueCatWebhook });

export default http;
