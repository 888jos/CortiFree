// Convex validates the JWTs issued by Convex Auth (convex/auth.ts) against
// the JWKS served at CONVEX_SITE_URL/.well-known/jwks.json (see http.ts).
export default {
  providers: [
    {
      domain: process.env.CONVEX_SITE_URL,
      applicationID: "convex",
    },
  ],
};
