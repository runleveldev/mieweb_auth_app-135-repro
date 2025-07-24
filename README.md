# Usage

1. Configure the build and the app server

```
# .env
BRANCH=<your git branch>
ROOT_URL=https://<your public url>
MAIL_URL=<your mail server>
EMAIL_ADMIN=
EMAIL_FROM=
FIREBASE_SERVICE_ACCOUNT_JSON='{..}'
```

2. Download `google-services.json` and `GoogleService-Info.plist` from the corresponding Firebase project and place in this directory.

3. Build the `mieweb_auth_app` container

```bash
docker build -t mieweb_auth_app --build-arg-file .env .
```

4. Run the docker compose

```bash
docker compose up -d
```

5. Get a copy of the APK

```bash
docker cp mieweb_auth_app-135-repro-app-1:/opt/mieweb_auth_app/android/app-release-signed.apk .
```

6. Install the App (or run in emulator)

```bash
adb install app-release-signed.apk
```

7. Attach to the loadbalancer and observe the logs

```bash
docker compose logs -f nginx
```

# Notes

- The container builds both the Android app and the server for convinience. To test on an Apple iPhone you must build the app yourself ensuring that the `--server` option is provided to match `ROOT_URL`
