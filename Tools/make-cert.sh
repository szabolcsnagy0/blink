#!/bin/sh
# One-time setup: a self-signed code-signing identity in the login keychain. Ad-hoc builds are
# pinned by hash, so every rebuild loses the Automation grant; builds signed with this
# identity share one designated requirement and keep it.
set -eu

NAME="Blink Local Signing"
KEYCHAIN="$HOME/Library/Keychains/login.keychain-db"

if security find-identity -v -p codesigning | grep -q "\"$NAME\""; then
    echo "$NAME is already set up."
    exit 0
fi

DIR=$(mktemp -d)
trap 'rm -rf "$DIR"' EXIT

if security find-certificate -c "$NAME" "$KEYCHAIN" >/dev/null 2>&1; then
    # Left by an earlier run that stopped before trusting it.
    security find-certificate -c "$NAME" -p "$KEYCHAIN" > "$DIR/cert.pem"
else
    cat > "$DIR/cert.cnf" <<EOF
[req]
distinguished_name = dn
x509_extensions = ext
prompt = no
[dn]
CN = $NAME
[ext]
basicConstraints = critical,CA:false
keyUsage = critical,digitalSignature
extendedKeyUsage = critical,codeSigning
EOF
    openssl req -x509 -newkey rsa:2048 -nodes -days 3650 -config "$DIR/cert.cnf" \
        -keyout "$DIR/key.pem" -out "$DIR/cert.pem" 2>/dev/null
    openssl pkcs12 -export -inkey "$DIR/key.pem" -in "$DIR/cert.pem" \
        -out "$DIR/identity.p12" -passout pass:blink
    security import "$DIR/identity.p12" -k "$KEYCHAIN" -P blink -T /usr/bin/codesign
fi

echo "Trusting the certificate for code signing; macOS asks for your password."
security add-trusted-cert -r trustRoot -p codeSign -k "$KEYCHAIN" "$DIR/cert.pem"

security find-identity -v -p codesigning | grep "\"$NAME\""
