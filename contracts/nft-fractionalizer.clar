;; This contract implements an NFT Fractionalizer - similar to ERC-1155 in Ethereum
;; It allows users to split NFTs into fungible fractions that can be traded separately
;; Think of it like "shares" of an NFT that multiple people can own

;; Implements the SFT (Semi-Fungible Token) trait - similar to ERC-1155 interface
;; This trait defines the standard functions that must be implemented
(impl-trait .sft-trait.sft-trait)

;; Import traits for NFT and FT (Fungible Token) functionality
;; Similar to importing interfaces in Solidity
(use-trait nft-trait .nft-trait.nft-trait)
(use-trait ft-trait .ft-trait.ft-trait)

;; Define the contract owner as the transaction sender (deployer)
;; In Clarity, tx-sender is like msg.sender in Solidity
(define-constant contract-owner tx-sender)

;; Define a fungible token called "fractions" - this is the ERC-20 equivalent
;; These tokens represent the fractional shares of NFTs
(define-fungible-token fractions)

;; Define a non-fungible token called "fractional-nft" with uint IDs
;; This tracks the original NFTs that get fractionalized
(define-non-fungible-token fractional-nft uint)

;; Map to track balances of specific token IDs for specific owners
;; Similar to mapping(uint => mapping(address => uint)) in Solidity
;; Structure: {id: token_id, owner: address} => balance_amount
(define-map balances
  {
    id: uint, ;; Token ID (like tokenId in Solidity)
    owner: principal, ;; Owner address (principal is like address in Solidity)
  }
  uint ;; Balance amount
)

;; Map to track total supply for each token ID
;; Similar to mapping(uint => uint) in Solidity
(define-map supplies
  uint
  uint
)

;; Map to store URIs for each token ID (metadata like IPFS links)
;; Similar to mapping(uint => string) in Solidity
(define-map uris
  uint
  (string-ascii 256)
)

;; Map to track which NFTs have been fractionalized
;; Structure: {id: token_id, nft: contract_address} => some_value
;; This prevents double-fractionalization of the same NFT
(define-map fractionalized-nfts
  {
    id: uint, ;; Token ID
    nft: principal, ;; NFT contract address
  }
  uint ;; Arbitrary value (could be 1 to mark as fractionalized)
)

;; Data variable to track the next available token ID
;; Similar to uint256 private _tokenIdCounter in Solidity
;; u0 is the literal 0 in Clarity
(define-data-var identifier uint u0)

;; Error constants - similar to custom errors in Solidity
;; In Clarity, errors are just numbers, but we give them meaningful names
(define-constant err-nft-recipient-only (err u101)) ;; Only recipient can call function
(define-constant err-nft-owner-only (err u102)) ;; Only NFT owner can call function
(define-constant err-unallowed-recipient (err u103)) ;; Cannot send to self

(define-constant err-insufficient-balance (err u200)) ;; Not enough tokens

(define-constant err-invalid-supply-value (err u300)) ;; Supply must be > 0
(define-constant err-invalid-nft-id (err u301)) ;; NFT ID doesn't exist

;; Read-only function to get balance of specific token ID for specific owner
;; Similar to balanceOf(address owner, uint256 id) in ERC-1155
(define-read-only (get-balance
    (id uint)
    (who principal)
  )
  (ok (default-to u0
    (map-get? balances ;; Get balance from map, default to 0 if not found {
      id: id, ;; Token ID to look up
      owner: who, ;; Owner address to look up
    })
  ))
)

;; Read-only function to get total balance across all token IDs for an owner
;; Similar to balanceOf(address owner) in ERC-20
(define-read-only (get-overall-balance (who principal))
  (ok (ft-get-balance fractions who))
  ;; Get total fungible token balance
)

;; Read-only function to get total supply of all fractional tokens
;; Similar to totalSupply() in ERC-20
(define-read-only (get-overall-supply)
  (ok (ft-get-supply fractions))
  ;; Get total supply of fungible tokens
)

;; Read-only function to get total supply of a specific token ID
;; Similar to totalSupply(uint256 id) in ERC-1155
(define-read-only (get-total-supply (id uint))
  (ok (default-to u0 (map-get? supplies id)))
  ;; Get supply from map, default to 0
)

;; Read-only function to get URI for a specific token ID
;; Similar to uri(uint256 id) in ERC-1155
(define-read-only (get-token-uri (id uint))
  (ok (default-to none (some (map-get? uris id))))
  ;; Get URI from map, return none if not found
)

;; Read-only function to get decimals for a token ID
;; Always returns 0 since we're dealing with whole number fractions
(define-read-only (get-decimals (id uint))
  (ok u0)
)

;; Public function to transfer tokens between addresses
;; Similar to safeTransferFrom in ERC-1155
(define-public (transfer
    (id uint)
    (amount uint)
    (sender principal)
    (recipient principal)
  )
  (let (
      ;; Get sender's current balance for this token ID
      (senderBalance (unwrap-panic (get-balance id sender)))
      ;; Get recipient's current balance for this token ID
      (recipientBalance (unwrap-panic (get-balance id recipient)))
    )
    ;; Ensure the transaction sender is the actual sender (like msg.sender == from in Solidity)
    (asserts! (is-eq tx-sender sender) err-nft-owner-only)
    ;; Prevent sending to self
    (asserts! (not (is-eq sender recipient)) err-unallowed-recipient)
    ;; Ensure sender has enough tokens
    (asserts! (<= amount senderBalance) err-insufficient-balance)

    ;; Transfer the fungible tokens (fractions)
    (try! (ft-transfer? fractions amount sender recipient))

    ;; Update the sender's balance in our custom map
    (map-set balances {
      id: id,
      owner: sender,
    }
      (- senderBalance amount)
    )
    ;; Update the recipient's balance in our custom map
    (map-set balances {
      id: id,
      owner: recipient,
    }
      (+ recipientBalance amount)
    )

    ;; Print event data (like emit Transfer in Solidity)
    (print {
      type: "sft_transfer",
      token-id: id,
      amount: amount,
      sender: sender,
      recipient: recipient,
    })
    (ok true)
    ;; Return success
  )
)

;; Public function to transfer with memo (like safeTransferFrom with data in ERC-1155)
(define-public (transfer-memo
    (id uint)
    (amount uint)
    (sender principal)
    (recipient principal)
    (memo (buff 34))
  )
  (begin
    ;; Call the regular transfer function
    (try! (transfer id amount sender recipient))
    ;; Print the memo data
    (print memo)
    (ok true)
  )
)

;; Public function to mint new fractionalized tokens
;; Similar to mint in ERC-1155 or ERC-20
(define-public (mint
    (recipient principal)
    (supply uint)
    (uri (string-ascii 256))
  )
  (let ((nft-id (+ (var-get identifier) u1)))
    ;; Generate new token ID
    ;; Ensure only recipient can mint to themselves (like onlyOwner in Solidity)
    (asserts! (is-eq tx-sender recipient) err-nft-recipient-only)
    ;; Ensure supply is greater than 0
    (asserts! (> supply u0) err-invalid-supply-value)

    ;; Mint the fungible tokens (fractions) to recipient
    (try! (ft-mint? fractions supply recipient))

    ;; Mint the NFT representation to the contract itself
    ;; This creates the "wrapper" NFT that represents the fractionalized asset
    (try! (nft-mint? fractional-nft nft-id (as-contract tx-sender)))

    ;; Store the supply for this token ID
    (map-set supplies nft-id supply)
    ;; Set initial balance for recipient
    (map-set balances {
      id: nft-id,
      owner: recipient,
    } supply
    )
    ;; Store the URI metadata
    (map-set uris nft-id uri)

    ;; Print mint event
    (print {
      type: "sft_mint",
      token-id: nft-id,
      amount: supply,
      recipient: recipient,
    })
    ;; Update the identifier counter
    (var-set identifier nft-id)
    (ok nft-id)
    ;; Return the new token ID
  )
)

;; Public function to retract (burn) all fractions and get back the original NFT
;; This is the reverse of fractionalization
(define-public (retract
    (id uint)
    (recipient principal)
  )
  (let (
      ;; Get recipient's balance for this token ID
      (balance (unwrap-panic (get-balance id recipient)))
      ;; Get total supply for this token ID
      (supply (unwrap-panic (get-total-supply id)))
    )
    ;; Ensure only recipient can retract
    (asserts! (is-eq tx-sender recipient) err-nft-recipient-only)
    ;; Ensure recipient owns ALL fractions (100% ownership required)
    (asserts! (is-eq balance supply) err-insufficient-balance)

    ;; Transfer the NFT back to the recipient from the contract
    ;; as-contract allows the contract to act as the sender
    (as-contract (try! (nft-transfer? fractional-nft id tx-sender recipient)))

    ;; Burn all the fractional tokens
    (try! (ft-burn? fractions balance recipient))

    ;; Clean up the data structures
    (map-delete balances {
      id: id,
      owner: recipient,
    })
    (map-delete supplies id)

    ;; Print retract event
    (print {
      type: "sft_burn",
      token-id: id,
      amount: balance,
      sender: recipient,
    })
    (ok true)
  )
)

;; Public function to fractionalize an existing NFT
;; This is the core function - takes an NFT and creates fractional tokens
(define-public (fractionalize
    (id uint)
    (recipient principal)
    (supply uint)
  )
  (let (
      ;; Get the current owner of the NFT
      (owner (unwrap! (nft-get-owner? fractional-nft id) err-invalid-nft-id))
    )
    ;; Ensure only recipient can fractionalize to themselves
    (asserts! (is-eq tx-sender recipient) err-nft-recipient-only)
    ;; Ensure the caller owns the NFT
    (asserts! (is-eq tx-sender owner) err-nft-owner-only)
    ;; Ensure supply is greater than 0
    (asserts! (> supply u0) err-invalid-supply-value)

    ;; Mint the fractional tokens to the recipient
    (try! (ft-mint? fractions supply recipient))

    ;; Store the supply and initial balance
    (map-set supplies id supply)
    (map-set balances {
      id: id,
      owner: recipient,
    } supply
    )

    ;; Print fractionalization event
    (print {
      type: "sft_mint",
      token-id: id,
      amount: supply,
      recipient: recipient,
    })
    (ok true)
  )
)
