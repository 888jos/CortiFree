import { httpRouter } from "convex/server";
import { auth } from "./auth";

const http = httpRouter();

// Serves /.well-known/openid-configuration and /.well-known/jwks.json, which
// Convex uses to verify the access tokens returned by `auth:signIn`.
auth.addHttpRoutes(http);

export default http;
