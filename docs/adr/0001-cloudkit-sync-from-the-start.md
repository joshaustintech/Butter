# Sync through CloudKit from the start

Recipes live only in the person's own iCloud, so the store uses CloudKit sync from the first release rather than starting local-only and adding it later. CloudKit forbids unique constraints, so Duplicates can't be prevented by the store: the import check catches them on one device, and a cleanup after sync merges ones created on two devices, removing only the newer copy and only if it hasn't been edited.
