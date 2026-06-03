#!/bin/bash
# Local HTTPS certificate generation for development
# Generates self-signed certificates for localhost development
# IMPORTANT: These certificates are for LOCAL DEVELOPMENT ONLY
# Never use these in production

set -euo pipefail

CERT_DIR=".certs"
CERT_NAME="localhost"
KEY_FILE="${CERT_DIR}/${CERT_NAME}.key"
CERT_FILE="${CERT_DIR}/${CERT_NAME}.crt"

# Create certificate directory
mkdir -p "$CERT_DIR"

# Cleanup function
cleanup() {
    if [ "$1" != "0" ]; then
        echo "❌ Error: Failed to generate certificates"
        exit 1
    fi
}

trap 'cleanup $?' EXIT

echo "🔐 SDIA Local HTTPS Certificate Generator"
echo "=========================================="
echo ""
echo "⚠️  IMPORTANT: These certificates are for LOCAL DEVELOPMENT ONLY"
echo "   Do not use in production."
echo ""

# Check if mkcert is available
if command -v mkcert >/dev/null 2>&1; then
    echo "✓ Using mkcert for certificate generation..."
    
    # Install local CA if not already done
    if ! mkcert -CAROOT >/dev/null 2>&1; then
        echo "Installing local CA..."
        mkcert -install
    fi
    
    # Generate certificates for localhost
    mkcert \
        -key-file "$KEY_FILE" \
        -cert-file "$CERT_FILE" \
        localhost 127.0.0.1 ::1
    
    echo ""
    echo "✅ Certificates generated with mkcert:"
    echo "   Key:  $KEY_FILE"
    echo "   Cert: $CERT_FILE"
    echo ""
    echo "📌 Your local CA has been installed in your system trust store."
    echo "   Browsers will recognize these certificates as valid."
    

else
    echo "⚠️  mkcert not found. Using OpenSSL fallback..."
    echo ""

    # Validate OpenSSL is available before using it
    if ! command -v openssl >/dev/null 2>&1; then
        echo "❌ Error: neither mkcert nor openssl is installed."
        echo ""
        echo "Install one of them and retry:"
        echo "  mkcert:  https://github.com/FiloSottile/mkcert"
        echo "  openssl: sudo apt update && sudo apt install -y openssl"
        exit 1
    fi

    echo "Generating self-signed certificate with OpenSSL..."

    # Generate private key and self-signed certificate using OpenSSL
    openssl req -x509 \
        -newkey rsa:2048 \
        -keyout "$KEY_FILE" \
        -out "$CERT_FILE" \
        -days 365 \
        -nodes \
        -subj "/CN=localhost/O=SDIA Local Dev/C=MX"

    echo ""
    echo "✅ Self-signed certificate generated with OpenSSL:"
    echo "   Key:  $KEY_FILE"
    echo "   Cert: $CERT_FILE"
    echo ""
    echo "📌 IMPORTANT: Browser will show security warning"
    echo "   This is expected for self-signed certificates."
    echo "   You can safely proceed ('Advanced' → 'Proceed')."
fi


echo ""
echo "📁 Certificate location: $CERT_DIR/"
ls -lh "$CERT_DIR/"
echo ""
echo "🚀 Next steps:"
echo "   1. Update your local development server config to use these files"
echo "   2. Restart your dev server (make dev)"
echo "   3. Navigate to https://localhost:5173 (frontend)"
echo "      or https://localhost:3000 (backend)"
echo ""
echo "🔒 Security reminder:"
echo "   - These certificates are NOT valid outside localhost"
echo "   - Do NOT commit these files (see .gitignore)"
echo "   - Regenerate if you change hostnames or IPs"
