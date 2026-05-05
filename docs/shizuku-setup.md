# Shizuku Setup *(Phase 6 — optional)*

> Phase 6 power-user feature. Not required for Phase 1.

[Shizuku](https://shizuku.rikka.app/) lets apps invoke privileged Android APIs without root, by relaying through a process started via ADB or a rooted shell. Some collectors that would otherwise require root or aren't possible at all become possible with Shizuku.

Panopticon will optionally use Shizuku for:

- Deeper system event hooks (TBD which specifically — depends on what we find we need).
- Reduced friction around battery optimization on aggressive OEMs.

**This is opt-in.** The default Panopticon install does not need Shizuku. If you don't set it up, you lose access to a small set of advanced collectors and gain nothing else.

---

## Decision: do you need this?

You probably do **not** need Shizuku if:

- You're on stock Android (Pixel) and the default permissions are working for you.
- You're not interested in the advanced collectors.
- You don't want to deal with re-arming Shizuku after every reboot (unless you have root).

You may want Shizuku if:

- You're on a hostile OEM (Xiaomi, Huawei) and the standard permission flow doesn't keep collectors alive.
- You want the Phase 6 advanced collectors.
- You're already using Shizuku for other apps and the marginal cost is zero.

---

## Setup *(forward-looking — Phase 6)*

To be written when Phase 6 ships. The general flow will be:

1. Install Shizuku from F-Droid or Play Store.
2. Start the Shizuku service via one of:
   - **ADB** (no root required, but resets after reboot): connect device to computer, run the command Shizuku gives you.
   - **Wireless ADB** (Android 11+, no computer required after first setup).
   - **Root** (persists across reboots).
3. In Panopticon, go to Permissions → Advanced → Enable Shizuku integration. The app will request permission via Shizuku.

---

## What Shizuku does NOT change

- Hard ethical rails still apply. Privileged access does not unlock surveillance of other people.
- Local-first still applies. No data leaves your device because of Shizuku.
- Per-source consent still applies. Each Shizuku-gated collector has its own toggle.
