import { newMockEvent } from "matchstick-as"
import { ethereum, BigInt, Address } from "@graphprotocol/graph-ts"
import {
  AI_DisputeClaimed,
  DipsuteAICreated,
  DisputeOracleCreated,
  DisputeResolvedByAI,
  DisputeResolvedByOracle,
  EscrowAccepted,
  EscrowCreated,
  EscrowDenied,
  EscrowRefunded,
  EscrowReleased,
  EscrowSubmitted,
  FeeWalletUpdated,
  Initialized,
  OracleDisputeStatusUpdated,
  OwnershipTransferred,
  ProofSubmitted,
  ResolverAddressUpdated,
  ResolverFeeUpdated,
  SignerAddressUpdated,
  TomiDisputeAddressUpdated,
  Upgraded
} from "../generated/EscrowPayment/EscrowPayment"

export function createAI_DisputeClaimedEvent(
  escrowId: BigInt,
  escrowIdStatus: i32
): AI_DisputeClaimed {
  let aiDisputeClaimedEvent = changetype<AI_DisputeClaimed>(newMockEvent())

  aiDisputeClaimedEvent.parameters = new Array()

  aiDisputeClaimedEvent.parameters.push(
    new ethereum.EventParam(
      "escrowId",
      ethereum.Value.fromUnsignedBigInt(escrowId)
    )
  )
  aiDisputeClaimedEvent.parameters.push(
    new ethereum.EventParam(
      "escrowIdStatus",
      ethereum.Value.fromUnsignedBigInt(BigInt.fromI32(escrowIdStatus))
    )
  )

  return aiDisputeClaimedEvent
}

export function createDipsuteAICreatedEvent(
  escrowID: BigInt,
  disputerAddress: Address
): DipsuteAICreated {
  let dipsuteAiCreatedEvent = changetype<DipsuteAICreated>(newMockEvent())

  dipsuteAiCreatedEvent.parameters = new Array()

  dipsuteAiCreatedEvent.parameters.push(
    new ethereum.EventParam(
      "escrowID",
      ethereum.Value.fromUnsignedBigInt(escrowID)
    )
  )
  dipsuteAiCreatedEvent.parameters.push(
    new ethereum.EventParam(
      "disputerAddress",
      ethereum.Value.fromAddress(disputerAddress)
    )
  )

  return dipsuteAiCreatedEvent
}

export function createDisputeOracleCreatedEvent(
  disputeOracleAddress: Address,
  escrowID: BigInt,
  disputerAddress: Address
): DisputeOracleCreated {
  let disputeOracleCreatedEvent = changetype<DisputeOracleCreated>(
    newMockEvent()
  )

  disputeOracleCreatedEvent.parameters = new Array()

  disputeOracleCreatedEvent.parameters.push(
    new ethereum.EventParam(
      "disputeOracleAddress",
      ethereum.Value.fromAddress(disputeOracleAddress)
    )
  )
  disputeOracleCreatedEvent.parameters.push(
    new ethereum.EventParam(
      "escrowID",
      ethereum.Value.fromUnsignedBigInt(escrowID)
    )
  )
  disputeOracleCreatedEvent.parameters.push(
    new ethereum.EventParam(
      "disputerAddress",
      ethereum.Value.fromAddress(disputerAddress)
    )
  )

  return disputeOracleCreatedEvent
}

export function createDisputeResolvedByAIEvent(
  escrowID: BigInt,
  winnerAddress: Address,
  timeStamp: BigInt
): DisputeResolvedByAI {
  let disputeResolvedByAiEvent = changetype<DisputeResolvedByAI>(newMockEvent())

  disputeResolvedByAiEvent.parameters = new Array()

  disputeResolvedByAiEvent.parameters.push(
    new ethereum.EventParam(
      "escrowID",
      ethereum.Value.fromUnsignedBigInt(escrowID)
    )
  )
  disputeResolvedByAiEvent.parameters.push(
    new ethereum.EventParam(
      "winnerAddress",
      ethereum.Value.fromAddress(winnerAddress)
    )
  )
  disputeResolvedByAiEvent.parameters.push(
    new ethereum.EventParam(
      "timeStamp",
      ethereum.Value.fromUnsignedBigInt(timeStamp)
    )
  )

  return disputeResolvedByAiEvent
}

export function createDisputeResolvedByOracleEvent(
  escrowID: BigInt,
  disputeContract: Address,
  winnerAddress: Address,
  timeStamp: BigInt
): DisputeResolvedByOracle {
  let disputeResolvedByOracleEvent = changetype<DisputeResolvedByOracle>(
    newMockEvent()
  )

  disputeResolvedByOracleEvent.parameters = new Array()

  disputeResolvedByOracleEvent.parameters.push(
    new ethereum.EventParam(
      "escrowID",
      ethereum.Value.fromUnsignedBigInt(escrowID)
    )
  )
  disputeResolvedByOracleEvent.parameters.push(
    new ethereum.EventParam(
      "disputeContract",
      ethereum.Value.fromAddress(disputeContract)
    )
  )
  disputeResolvedByOracleEvent.parameters.push(
    new ethereum.EventParam(
      "winnerAddress",
      ethereum.Value.fromAddress(winnerAddress)
    )
  )
  disputeResolvedByOracleEvent.parameters.push(
    new ethereum.EventParam(
      "timeStamp",
      ethereum.Value.fromUnsignedBigInt(timeStamp)
    )
  )

  return disputeResolvedByOracleEvent
}

export function createEscrowAcceptedEvent(
  escrowId: BigInt,
  escrowIdStatus: i32
): EscrowAccepted {
  let escrowAcceptedEvent = changetype<EscrowAccepted>(newMockEvent())

  escrowAcceptedEvent.parameters = new Array()

  escrowAcceptedEvent.parameters.push(
    new ethereum.EventParam(
      "escrowId",
      ethereum.Value.fromUnsignedBigInt(escrowId)
    )
  )
  escrowAcceptedEvent.parameters.push(
    new ethereum.EventParam(
      "escrowIdStatus",
      ethereum.Value.fromUnsignedBigInt(BigInt.fromI32(escrowIdStatus))
    )
  )

  return escrowAcceptedEvent
}

export function createEscrowCreatedEvent(
  escrowdetails: ethereum.Tuple,
  escrowFee: BigInt
): EscrowCreated {
  let escrowCreatedEvent = changetype<EscrowCreated>(newMockEvent())

  escrowCreatedEvent.parameters = new Array()

  escrowCreatedEvent.parameters.push(
    new ethereum.EventParam(
      "escrowdetails",
      ethereum.Value.fromTuple(escrowdetails)
    )
  )
  escrowCreatedEvent.parameters.push(
    new ethereum.EventParam(
      "escrowFee",
      ethereum.Value.fromUnsignedBigInt(escrowFee)
    )
  )

  return escrowCreatedEvent
}

export function createEscrowDeniedEvent(
  escrowId: BigInt,
  escrowIdStatus: i32
): EscrowDenied {
  let escrowDeniedEvent = changetype<EscrowDenied>(newMockEvent())

  escrowDeniedEvent.parameters = new Array()

  escrowDeniedEvent.parameters.push(
    new ethereum.EventParam(
      "escrowId",
      ethereum.Value.fromUnsignedBigInt(escrowId)
    )
  )
  escrowDeniedEvent.parameters.push(
    new ethereum.EventParam(
      "escrowIdStatus",
      ethereum.Value.fromUnsignedBigInt(BigInt.fromI32(escrowIdStatus))
    )
  )

  return escrowDeniedEvent
}

export function createEscrowRefundedEvent(
  escrowId: BigInt,
  escrowIdStatus: i32
): EscrowRefunded {
  let escrowRefundedEvent = changetype<EscrowRefunded>(newMockEvent())

  escrowRefundedEvent.parameters = new Array()

  escrowRefundedEvent.parameters.push(
    new ethereum.EventParam(
      "escrowId",
      ethereum.Value.fromUnsignedBigInt(escrowId)
    )
  )
  escrowRefundedEvent.parameters.push(
    new ethereum.EventParam(
      "escrowIdStatus",
      ethereum.Value.fromUnsignedBigInt(BigInt.fromI32(escrowIdStatus))
    )
  )

  return escrowRefundedEvent
}

export function createEscrowReleasedEvent(
  escrowId: BigInt,
  escrowIdStatus: i32,
  amountReleased: BigInt
): EscrowReleased {
  let escrowReleasedEvent = changetype<EscrowReleased>(newMockEvent())

  escrowReleasedEvent.parameters = new Array()

  escrowReleasedEvent.parameters.push(
    new ethereum.EventParam(
      "escrowId",
      ethereum.Value.fromUnsignedBigInt(escrowId)
    )
  )
  escrowReleasedEvent.parameters.push(
    new ethereum.EventParam(
      "escrowIdStatus",
      ethereum.Value.fromUnsignedBigInt(BigInt.fromI32(escrowIdStatus))
    )
  )
  escrowReleasedEvent.parameters.push(
    new ethereum.EventParam(
      "amountReleased",
      ethereum.Value.fromUnsignedBigInt(amountReleased)
    )
  )

  return escrowReleasedEvent
}

export function createEscrowSubmittedEvent(
  escrowId: BigInt,
  escrowIdStatus: i32
): EscrowSubmitted {
  let escrowSubmittedEvent = changetype<EscrowSubmitted>(newMockEvent())

  escrowSubmittedEvent.parameters = new Array()

  escrowSubmittedEvent.parameters.push(
    new ethereum.EventParam(
      "escrowId",
      ethereum.Value.fromUnsignedBigInt(escrowId)
    )
  )
  escrowSubmittedEvent.parameters.push(
    new ethereum.EventParam(
      "escrowIdStatus",
      ethereum.Value.fromUnsignedBigInt(BigInt.fromI32(escrowIdStatus))
    )
  )

  return escrowSubmittedEvent
}

export function createFeeWalletUpdatedEvent(
  oldFeeWallet: Address,
  newFeeWallet: Address
): FeeWalletUpdated {
  let feeWalletUpdatedEvent = changetype<FeeWalletUpdated>(newMockEvent())

  feeWalletUpdatedEvent.parameters = new Array()

  feeWalletUpdatedEvent.parameters.push(
    new ethereum.EventParam(
      "oldFeeWallet",
      ethereum.Value.fromAddress(oldFeeWallet)
    )
  )
  feeWalletUpdatedEvent.parameters.push(
    new ethereum.EventParam(
      "newFeeWallet",
      ethereum.Value.fromAddress(newFeeWallet)
    )
  )

  return feeWalletUpdatedEvent
}

export function createInitializedEvent(version: BigInt): Initialized {
  let initializedEvent = changetype<Initialized>(newMockEvent())

  initializedEvent.parameters = new Array()

  initializedEvent.parameters.push(
    new ethereum.EventParam(
      "version",
      ethereum.Value.fromUnsignedBigInt(version)
    )
  )

  return initializedEvent
}

export function createOracleDisputeStatusUpdatedEvent(
  oldDisputeStatus: boolean,
  newDisputeStatus: boolean
): OracleDisputeStatusUpdated {
  let oracleDisputeStatusUpdatedEvent = changetype<OracleDisputeStatusUpdated>(
    newMockEvent()
  )

  oracleDisputeStatusUpdatedEvent.parameters = new Array()

  oracleDisputeStatusUpdatedEvent.parameters.push(
    new ethereum.EventParam(
      "oldDisputeStatus",
      ethereum.Value.fromBoolean(oldDisputeStatus)
    )
  )
  oracleDisputeStatusUpdatedEvent.parameters.push(
    new ethereum.EventParam(
      "newDisputeStatus",
      ethereum.Value.fromBoolean(newDisputeStatus)
    )
  )

  return oracleDisputeStatusUpdatedEvent
}

export function createOwnershipTransferredEvent(
  previousOwner: Address,
  newOwner: Address
): OwnershipTransferred {
  let ownershipTransferredEvent = changetype<OwnershipTransferred>(
    newMockEvent()
  )

  ownershipTransferredEvent.parameters = new Array()

  ownershipTransferredEvent.parameters.push(
    new ethereum.EventParam(
      "previousOwner",
      ethereum.Value.fromAddress(previousOwner)
    )
  )
  ownershipTransferredEvent.parameters.push(
    new ethereum.EventParam("newOwner", ethereum.Value.fromAddress(newOwner))
  )

  return ownershipTransferredEvent
}

export function createProofSubmittedEvent(
  escrowId: BigInt,
  disputeContract: Address,
  submittedBy: Address,
  proofURI: string
): ProofSubmitted {
  let proofSubmittedEvent = changetype<ProofSubmitted>(newMockEvent())

  proofSubmittedEvent.parameters = new Array()

  proofSubmittedEvent.parameters.push(
    new ethereum.EventParam(
      "escrowId",
      ethereum.Value.fromUnsignedBigInt(escrowId)
    )
  )
  proofSubmittedEvent.parameters.push(
    new ethereum.EventParam(
      "disputeContract",
      ethereum.Value.fromAddress(disputeContract)
    )
  )
  proofSubmittedEvent.parameters.push(
    new ethereum.EventParam(
      "submittedBy",
      ethereum.Value.fromAddress(submittedBy)
    )
  )
  proofSubmittedEvent.parameters.push(
    new ethereum.EventParam("proofURI", ethereum.Value.fromString(proofURI))
  )

  return proofSubmittedEvent
}

export function createResolverAddressUpdatedEvent(
  oldResolverAI: Address,
  newResolverAI: Address
): ResolverAddressUpdated {
  let resolverAddressUpdatedEvent = changetype<ResolverAddressUpdated>(
    newMockEvent()
  )

  resolverAddressUpdatedEvent.parameters = new Array()

  resolverAddressUpdatedEvent.parameters.push(
    new ethereum.EventParam(
      "oldResolverAI",
      ethereum.Value.fromAddress(oldResolverAI)
    )
  )
  resolverAddressUpdatedEvent.parameters.push(
    new ethereum.EventParam(
      "newResolverAI",
      ethereum.Value.fromAddress(newResolverAI)
    )
  )

  return resolverAddressUpdatedEvent
}

export function createResolverFeeUpdatedEvent(
  oldResolverFee: BigInt,
  newResolverFee: BigInt
): ResolverFeeUpdated {
  let resolverFeeUpdatedEvent = changetype<ResolverFeeUpdated>(newMockEvent())

  resolverFeeUpdatedEvent.parameters = new Array()

  resolverFeeUpdatedEvent.parameters.push(
    new ethereum.EventParam(
      "oldResolverFee",
      ethereum.Value.fromUnsignedBigInt(oldResolverFee)
    )
  )
  resolverFeeUpdatedEvent.parameters.push(
    new ethereum.EventParam(
      "newResolverFee",
      ethereum.Value.fromUnsignedBigInt(newResolverFee)
    )
  )

  return resolverFeeUpdatedEvent
}

export function createSignerAddressUpdatedEvent(
  oldSigner: Address,
  newSigner: Address
): SignerAddressUpdated {
  let signerAddressUpdatedEvent = changetype<SignerAddressUpdated>(
    newMockEvent()
  )

  signerAddressUpdatedEvent.parameters = new Array()

  signerAddressUpdatedEvent.parameters.push(
    new ethereum.EventParam("oldSigner", ethereum.Value.fromAddress(oldSigner))
  )
  signerAddressUpdatedEvent.parameters.push(
    new ethereum.EventParam("newSigner", ethereum.Value.fromAddress(newSigner))
  )

  return signerAddressUpdatedEvent
}

export function createTomiDisputeAddressUpdatedEvent(
  oldTomiDispute: Address,
  newTomiDispute: Address
): TomiDisputeAddressUpdated {
  let tomiDisputeAddressUpdatedEvent = changetype<TomiDisputeAddressUpdated>(
    newMockEvent()
  )

  tomiDisputeAddressUpdatedEvent.parameters = new Array()

  tomiDisputeAddressUpdatedEvent.parameters.push(
    new ethereum.EventParam(
      "oldTomiDispute",
      ethereum.Value.fromAddress(oldTomiDispute)
    )
  )
  tomiDisputeAddressUpdatedEvent.parameters.push(
    new ethereum.EventParam(
      "newTomiDispute",
      ethereum.Value.fromAddress(newTomiDispute)
    )
  )

  return tomiDisputeAddressUpdatedEvent
}

export function createUpgradedEvent(implementation: Address): Upgraded {
  let upgradedEvent = changetype<Upgraded>(newMockEvent())

  upgradedEvent.parameters = new Array()

  upgradedEvent.parameters.push(
    new ethereum.EventParam(
      "implementation",
      ethereum.Value.fromAddress(implementation)
    )
  )

  return upgradedEvent
}
