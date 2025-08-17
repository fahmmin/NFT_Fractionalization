# 🧩 NFT Fractionalization Vault (Stacks)

## 📜 Project Description

This project is an on-chain **NFT fractionalization** system built in **Clarity** and deployed on the **Stacks Testnet**. It lets a creator wrap any unique asset as a custodial **vault NFT**, then distribute **fractional claim tokens** to multiple holders. All minting, transfers, redemptions, and metadata are enforced by the smart contract—so the entire lifecycle is **trustless, auditable, and transparent**.

Under the hood, the contract mints:

* a **vault NFT** (one per asset/vault), and
* a **fungible “fractions” token** tied to that vault’s ID.

Holders can trade fractions, and when someone (or a group) accumulates **100%** of the fractions for a given vault, they can **redeem** and receive the underlying NFT back from the contract.

---

## 🔭 Project Vision

The goal is to make high-value, unique assets **accessible and programmable**:

* Enable **shared ownership** and price discovery for unique items (art, licenses, domain NFTs, etc.).
* Provide a **standard, auditable mechanism** to split, transfer, and reunify ownership.
* Serve as a **building block** for use cases like transparent fund/program disbursement, DAOs, and collateralized lending.

---

## ⭐ Key Features

* ✅ **One-Vault-Per-Asset Model:** Each asset is represented by a single **vault NFT** held by the contract.
* 🪙 **Fractional Shares (FT):** Mints a fungible token supply (per vault ID) that encodes ownership percentages.
* 🔄 **Transfers & Memo Support:** Send fractions with optional memo data (e.g., references, trade notes).
* 🏷️ **On-Chain Metadata:** Store/return a per-vault URI for off-chain metadata (IPFS/HTTPS) and retrieve token info via read-only functions.
* 🧮 **Total Supply & Balances:** Built-in views for per-ID balances, total supply, and overall balances.
* 🔓 **Full Redemption:** When one account holds **100%** of a vault’s fractions, they can **redeem** to claim the underlying NFT and burn the fractions.
* 🔐 **No Middlemen:** All actions (mint, transfer, redeem) are enforced by the smart contract.

---

## 🚀 Future Scope

* 🧩 **Front-End DApp:** Build a React + Stacks.js UI to mint, transfer, and redeem fractions easily.
* 🧾 **URI + Hash Anchoring:** Add a SHA-256 hash to anchor legal docs/terms alongside the metadata URI.
* 🧠 **Governance Hooks:** Gate certain actions behind DAO or multisig approvals.
* 💰 **Treasury / Royalty:** Optional fees to a treasury or creator on transfers/redemptions.
* 🏛️ **Public Fund Disbursement:** Represent a program as a vault NFT and use fractions as **claim rights** for transparent, on-chain payouts.
* 🧪 **Testing & Audits:** Extend unit tests, fuzz scenarios for redemption/rounding, and commission third-party audits.

---

## 🛠️ Interacting On-Chain (Hiro Explorer)

**Read-only (no signature):**

* `get-balance(id, who)` — fraction balance for a vault ID
* `get-total-supply(id)` — total fractions for a vault ID
* `get-overall-balance(who)` — sum of all fractions held by a principal
* `get-overall-supply()` — total minted across all vaults
* `get-token-uri(id)` — metadata URI for the vault NFT

**Contract calls (signature required):**

* `mint(recipient, supply, uri)` → creates a new vault:

  * Mints **fractions** to `recipient`.
  * Mints the **vault NFT** (same `id`) to the **contract**.
  * Associates the `uri` with that vault.
* `transfer(id, amount, sender, recipient)` → move fractions.
* `transfer-memo(id, amount, sender, recipient, memo)` → move fractions with memo.
* `retract(id, recipient)` → if `recipient` holds **100%** of fractions for `id`, burn them and transfer the **vault NFT** from the contract to `recipient`.

**Common errors you might see:**

* `err u101/u102` — caller must match the declared sender/recipient
* `err u103` — invalid recipient (e.g., self-transfer)
* `err u200` — insufficient balance / not 100% for redemption
* `err u300` — invalid supply (must be > 0)
* `err u301` — invalid vault ID

---

## 🧭 Suggested Workflows

**Create & Distribute:**

1. Call `mint(recipient, supply, uri)` to create a new vault `id`.
2. Distribute fractions via `transfer` or list them on a marketplace that supports SIP-010.

**Reunify & Redeem:**

1. Accumulate **all** fractions for a given `id`.
2. Call `retract(id, recipient)` to burn fractions and claim the vault NFT.

**Audit & Track:**

* Use read-only views and Explorer events to track minting, transfers, and redemption on-chain.

---

## 📦 Contract Details

Deployed contract address: STGZ43RPQ8MRR7ZQ7NNH09K3BZ9NY7B66MYFWKJ3.nft-fractionalizer

<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/4009809d-f702-4687-b0d4-9b00e2de07fe" />
<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/0000aa4e-cca3-4ad2-a289-b23e5131cf91" />
<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/b343e8b4-b4b6-46c3-8fbc-c836eb50f65a" />


> Tip: On Hiro Explorer, use the **Read only functions** panel to confirm balances and supplies before making transfers or attempting redemption.

---

## 🧱 Standards & Compatibility

* Built with **Clarity** on **Stacks**
* Compatible with SIP-009 (NFT), SIP-010 (FT) patterns
* Designed to compose with wallets, marketplaces, and explorer tools in the Stacks ecosystem

---

If you’d like, share your deployed **contract ID** and I’ll tailor the “Contract Details” section and add copy-paste examples for each function call in Hiro Explorer.
