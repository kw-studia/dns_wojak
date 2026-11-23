#!/usr/bin/env bash
# Test serwera DNS po wdrożeniu (wspólne kryteria testów projektu).
# Użycie: OBRAZ=... TAG=... IP_PROD=... test_dns.sh <adres IP testowanego serwera>
# Zapytania wykonuje polecenie dig z wdrażanego obrazu (na serwerze nie trzeba instalować dnsutils).
set -u
SERWER="$1"

# Oczekiwany numer seryjny = numer z pliku strefy w obrazie, który miał zostać wdrożony
OCZEKIWANY=$(docker run --rm "$OBRAZ:$TAG" named-checkzone wojak.lan /etc/bind/db.wojak.lan \
  | sed -n 's/.*loaded serial \([0-9]*\).*/\1/p')

zapytaj() { docker run --rm --network host "$OBRAZ:$TAG" dig @"$SERWER" +short "$@"; }

echo "Serwer: $SERWER, obraz: $OBRAZ:$TAG"
for PROBA in 1 2 3 4 5; do
  A=$(zapytaj www.wojak.lan A)
  PTR=$(zapytaj -x "$IP_PROD")
  SOA=$(zapytaj wojak.lan SOA | awk '{print $3}')
  echo "Próba $PROBA:"
  echo "  A www.wojak.lan     = $A (oczekiwany $IP_PROD)"
  echo "  PTR $IP_PROD    = $PTR (oczekiwany prod.wojak.lan.)"
  echo "  SOA wojak.lan serial = $SOA (oczekiwany $OCZEKIWANY)"
  if [ "$A" = "$IP_PROD" ] && [ "$PTR" = "prod.wojak.lan." ] && [ -n "$OCZEKIWANY" ] && [ "$SOA" = "$OCZEKIWANY" ]; then
    echo "Test po wdrożeniu zakończony sukcesem"
    exit 0
  fi
  sleep 3
done
echo "::error::Test po wdrożeniu na $SERWER nie powiódł się"
exit 1