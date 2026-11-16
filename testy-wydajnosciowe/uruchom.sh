#!/usr/bin/env bash
# Seria testow obciazeniowych JMeter: 1, 5, 10 i 20 jednoczesnych pracownikow.
# Uruchom z katalogu testy-wydajnosciowe (backend musi dzialac na porcie 8000):
#   bash uruchom.sh
CZAS=120
for U in 1 5 10 20; do
  KATALOG="wyniki/u$U"
  rm -rf "$KATALOG" && mkdir -p "$KATALOG"
  echo "=== Pomiar dla $U uzytkownikow ($CZAS s) ==="
  jmeter -n -t wms_obciazenie.jmx -Jusers=$U -Jrampup=10 -Jduration=$CZAS \
    -l "$KATALOG/wyniki.jtl" -j "$KATALOG/jmeter.log" -e -o "$KATALOG/raport"
  sleep 10
done
echo "Gotowe. Przeslij pliki wyniki/u*/raport/statistics.json"
