#!/bin/sh

XRAY_URL="https://dl.vpnje.com/xray.260206"
XRAY_TMP="/tmp/xray.260206"
XRAY_BIN="/usr/bin/xray"

# Download Xray Core
wget -O "$XRAY_TMP" "$XRAY_URL" || exit 1

# Check downloaded binary
chmod 755 "$XRAY_TMP"
"$XRAY_TMP" version || exit 1

# Stop PassWall services
/etc/init.d/passwall stop >/dev/null 2>&1
/etc/init.d/passwall2 stop >/dev/null 2>&1

# Install Xray Core
mv -f "$XRAY_TMP" "$XRAY_BIN" || exit 1

# Direct configuration without UCI commands
set_xray_path() {
    FILE="$1"

    [ -f "$FILE" ] || return 1

    cp -p "$FILE" "$FILE.bak" || return 1

    awk '
    /^config[ \t]+/ {
        if (target && !found)
            print "\toption xray_file \047/usr/bin/xray\047"

        target = ($2 == "global_app")
        found = 0
        seen += target
        print
        next
    }

    target && /^[ \t]*option[ \t]+xray_file[ \t]/ {
        print "\toption xray_file \047/usr/bin/xray\047"
        found = 1
        next
    }

    { print }

    END {
        if (target && !found)
            print "\toption xray_file \047/usr/bin/xray\047"

        if (!seen)
            exit 2
    }
    ' "$FILE" > "$FILE.tmp" || {
        rm -f "$FILE.tmp"
        return 1
    }

    mv -f "$FILE.tmp" "$FILE"
}

# Update PassWall
set_xray_path /etc/config/passwall || exit 1

# Update PassWall2
set_xray_path /etc/config/passwall2 || exit 1

# Restart services
/etc/init.d/passwall start >/dev/null 2>&1
/etc/init.d/passwall2 start >/dev/null 2>&1

echo "Xray path configured successfully."
echo "Xray binary: $XRAY_BIN"

# Verify installation
/usr/bin/xray version
rm -rf "$0"
sleep 1 >/dev/null 2>&1
reboot
