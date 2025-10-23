import { Bytes } from "@graphprotocol/graph-ts"
import {
  AI_DisputeClaimed as AI_DisputeClaimedEvent,
  DipsuteAICreated as DipsuteAICreatedEvent,
  DisputeOracleCreated as DisputeOracleCreatedEvent,
  DisputeResolvedByAI as DisputeResolvedByAIEvent,
  DisputeResolvedByOracle as DisputeResolvedByOracleEvent,
  EscrowAccepted as EscrowAcceptedEvent,
  EscrowCreated as EscrowCreatedEvent,
  EscrowDenied as EscrowDeniedEvent,
  EscrowRefunded as EscrowRefundedEvent,
  EscrowReleased as EscrowReleasedEvent,
  EscrowSubmitted as EscrowSubmittedEvent,
  FeeWalletUpdated as FeeWalletUpdatedEvent,
  Initialized as InitializedEvent,
  OracleDisputeStatusUpdated as OracleDisputeStatusUpdatedEvent,
  OwnershipTransferred as OwnershipTransferredEvent,
  ProofSubmitted as ProofSubmittedEvent,
  ResolverAddressUpdated as ResolverAddressUpdatedEvent,
  ResolverFeeUpdated as ResolverFeeUpdatedEvent,
  SignerAddressUpdated as SignerAddressUpdatedEvent,
  TomiDisputeAddressUpdated as TomiDisputeAddressUpdatedEvent,
  Upgraded as UpgradedEvent
} from "../generated/EscrowPayment/EscrowPayment"
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
} from "../generated/schema"

export function handleAI_DisputeClaimed(event: AI_DisputeClaimedEvent): void {
  let entity = new AI_DisputeClaimed(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.escrowId = event.params.escrowId
  entity.escrowIdStatus = event.params.escrowIdStatus

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleDipsuteAICreated(event: DipsuteAICreatedEvent): void {
  let entity = new DipsuteAICreated(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.escrowID = event.params.escrowID
  entity.disputerAddress = event.params.disputerAddress

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleDisputeOracleCreated(
  event: DisputeOracleCreatedEvent
): void {
  let entity = new DisputeOracleCreated(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.escrowID = event.params.escrowID
  entity.disputerAddress = event.params.disputerAddress

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleDisputeResolvedByAI(
  event: DisputeResolvedByAIEvent
): void {
  let entity = new DisputeResolvedByAI(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.escrowID = event.params.escrowID
  entity.winnerAddress = event.params.winnerAddress
  entity.timeStamp = event.params.timeStamp

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleDisputeResolvedByOracle(
  event: DisputeResolvedByOracleEvent
): void {
  let entity = new DisputeResolvedByOracle(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.escrowID = event.params.escrowID
  entity.disputeContract = event.params.disputeContract
  entity.winnerAddress = event.params.winnerAddress
  entity.timeStamp = event.params.timeStamp

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()

}

export function handleEscrowAccepted(event: EscrowAcceptedEvent): void {
  let entity = new EscrowAccepted(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.escrowId = event.params.escrowId
  entity.escrowIdStatus = event.params.escrowIdStatus

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
  let escrowCreated = EscrowCreated.load(Bytes.fromUTF8(event.params.escrowId.toString()))
  if (escrowCreated != null) {
    escrowCreated.escrowdetails_status = event.params.escrowIdStatus
    escrowCreated.save()
  }
}

export function handleEscrowCreated(event: EscrowCreatedEvent): void {
  // Use escrow ID as the entity ID (converted to string and then to Bytes)
  const escrowId = event.params.escrowdetails.escrowID.toString()
  let entity = new EscrowCreated(Bytes.fromUTF8(escrowId))
  entity.escrowdetails_escrowID = event.params.escrowdetails.escrowID
  entity.escrowdetails_escrowDetialsURI =
    event.params.escrowdetails.escrowDetialsURI
  entity.escrowdetails_submissionURI = event.params.escrowdetails.submissionURI
  entity.escrowdetails_fromAddress = event.params.escrowdetails.fromAddress
  entity.escrowdetails_toAddress = event.params.escrowdetails.toAddress
  entity.escrowdetails_tokenAddress = event.params.escrowdetails.tokenAddress
  entity.escrowdetails_tokenAmount = event.params.escrowdetails.tokenAmount
  entity.escrowdetails_submissionDeadline =
    event.params.escrowdetails.submissionDeadline
  entity.escrowdetails_resultTime = event.params.escrowdetails.resultTime
  entity.escrowdetails_status = event.params.escrowdetails.status
  entity.escrowdetails_disputeType = event.params.escrowdetails.disputeType
  entity.escrowFee = event.params.escrowFee

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleEscrowDenied(event: EscrowDeniedEvent): void {
  let entity = new EscrowDenied(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.escrowId = event.params.escrowId
  entity.escrowIdStatus = event.params.escrowIdStatus

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
  let escrowCreated = EscrowCreated.load(Bytes.fromUTF8(event.params.escrowId.toString()))
  if (escrowCreated != null) {
    escrowCreated.escrowdetails_status = event.params.escrowIdStatus
    escrowCreated.save()
  }
}

export function handleEscrowRefunded(event: EscrowRefundedEvent): void {
  let entity = new EscrowRefunded(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.escrowId = event.params.escrowId
  entity.escrowIdStatus = event.params.escrowIdStatus

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
  let escrowCreated = EscrowCreated.load(Bytes.fromUTF8(event.params.escrowId.toString()))
  if (escrowCreated != null) {
    escrowCreated.escrowdetails_status = event.params.escrowIdStatus
    escrowCreated.save()
  }
}

export function handleEscrowReleased(event: EscrowReleasedEvent): void {
  let entity = new EscrowReleased(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.escrowId = event.params.escrowId
  entity.escrowIdStatus = event.params.escrowIdStatus
  entity.amountReleased = event.params.amountReleased

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
  let escrowCreated = EscrowCreated.load(Bytes.fromUTF8(event.params.escrowId.toString()))
  if (escrowCreated != null) {
    escrowCreated.escrowdetails_status = event.params.escrowIdStatus
    escrowCreated.save()
  }
}

export function handleEscrowSubmitted(event: EscrowSubmittedEvent): void {
  let entity = new EscrowSubmitted(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.escrowId = event.params.escrowId
  entity.escrowIdStatus = event.params.escrowIdStatus

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
  let escrowCreated = EscrowCreated.load(Bytes.fromUTF8(event.params.escrowId.toString()))
  if (escrowCreated != null) {
    escrowCreated.escrowdetails_status = event.params.escrowIdStatus
    escrowCreated.save()
  }
}

export function handleFeeWalletUpdated(event: FeeWalletUpdatedEvent): void {
  let entity = new FeeWalletUpdated(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.oldFeeWallet = event.params.oldFeeWallet
  entity.newFeeWallet = event.params.newFeeWallet

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleInitialized(event: InitializedEvent): void {
  let entity = new Initialized(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.version = event.params.version

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleOracleDisputeStatusUpdated(
  event: OracleDisputeStatusUpdatedEvent
): void {
  let entity = new OracleDisputeStatusUpdated(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.oldDisputeStatus = event.params.oldDisputeStatus
  entity.newDisputeStatus = event.params.newDisputeStatus

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleOwnershipTransferred(
  event: OwnershipTransferredEvent
): void {
  let entity = new OwnershipTransferred(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.previousOwner = event.params.previousOwner
  entity.newOwner = event.params.newOwner

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleProofSubmitted(event: ProofSubmittedEvent): void {
  let entity = new ProofSubmitted(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.escrowId = event.params.escrowId
  entity.disputeContract = event.params.disputeContract
  entity.submittedBy = event.params.submittedBy
  entity.proofURI = event.params.proofURI

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleResolverAddressUpdated(
  event: ResolverAddressUpdatedEvent
): void {
  let entity = new ResolverAddressUpdated(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.oldResolverAI = event.params.oldResolverAI
  entity.newResolverAI = event.params.newResolverAI

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleResolverFeeUpdated(event: ResolverFeeUpdatedEvent): void {
  let entity = new ResolverFeeUpdated(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.oldResolverFee = event.params.oldResolverFee
  entity.newResolverFee = event.params.newResolverFee

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleSignerAddressUpdated(
  event: SignerAddressUpdatedEvent
): void {
  let entity = new SignerAddressUpdated(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.oldSigner = event.params.oldSigner
  entity.newSigner = event.params.newSigner

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleTomiDisputeAddressUpdated(
  event: TomiDisputeAddressUpdatedEvent
): void {
  let entity = new TomiDisputeAddressUpdated(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.oldTomiDispute = event.params.oldTomiDispute
  entity.newTomiDispute = event.params.newTomiDispute

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleUpgraded(event: UpgradedEvent): void {
  let entity = new Upgraded(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.implementation = event.params.implementation

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}
