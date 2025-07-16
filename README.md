# Usage

1. Make an NGROK account and claim a static domain

2. Configure the build and the app server

```
# .env
NGROK_AUTHTOKEN=<from ngrok>
NGROK_URL=<ngrok static domain>
BRANCH=<your git branch>
ROOT_URL=https://${NGROK_URL}
MAIL_URL=<your mail server>
EMAIL_ADMIN=
EMAIL_FROM=
FIREBASE_SERVICE_ACCOUNT_JSON='{..}'
```

3. Download `google-services.json` and `GoogleService-Info.plist` from the corresponding Firebase project and place in this directory.

4. Build the `mieweb_auth_app` container

```bash
docker build -t mieweb_auth_app --build-arg-file .env .
```

5. Run the docker compose

```bash
docker compose up -d
```

6. Get a copy of the APK

```bash
docker cp mieweb_auth_app-135-repro-app-1:/opt/mieweb_auth_app/android/app-release-signed.apk .
```

7. Install the App (or run in emulator)

```bash
adb install app-release-signed.apk
```

8. Attach to the loadbalancer and observe the logs

```bash
docker compose logs -f nginx
```

# Notes

- The container builds both the Android app and the server for convinience. To test on an Apple iPhone you must build the app yourself ensuring that the `--server` option is provided to match `ROOT_URL`