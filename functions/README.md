# DeepSeek proxy

The mobile app calls `deepSeekChat`. This function calls DeepSeek server-side.

Set the secret once:

```sh
firebase functions:secrets:set DEEPSEEK_API_KEY --project cortifree-app
firebase deploy --only functions:deepSeekChat --project cortifree-app
```

The DeepSeek key must never be added to `Info.plist`, Firestore, source code, or the mobile app bundle.
