;; NFT (Non-Fungible Token) trait - similar to ERC-721 interface in Ethereum
;; This defines the standard functions that any NFT contract must implement
;; Think of this as an interface/abstract contract in Solidity for ERC-721 tokens
(define-trait nft-trait (
  (get-last-token-id
    ()
    (response uint uint)
  )
  (get-token-uri
    (uint)
    (response (optional (string-ascii 256)) uint)
  )
  (get-owner
    (uint)
    (response (optional principal) uint)
  )
  (transfer
    (uint principal principal)
    (response bool uint)
  )
))
