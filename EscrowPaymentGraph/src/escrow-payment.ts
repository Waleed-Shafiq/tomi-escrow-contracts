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
  Initialized as InitializedEvent,
  OwnershipTransferred as OwnershipTransferredEvent,
  ProofSubmitted as ProofSubmittedEvent,
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
  Initialized,
  OwnershipTransferred,
  ProofSubmitted,
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
}

export function handleEscrowCreated(event: EscrowCreatedEvent): void {
  let entity = new EscrowCreated(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.escrowdetails_escrowDetialsURI =
    event.params.escrowdetails.escrowDetialsURI
  entity.escrowdetails_submissionURI = event.params.escrowdetails.submissionURI
  entity.escrowdetails_fromAddress = event.params.escrowdetails.fromAddress
  entity.escrowdetails_toAddress = event.params.escrowdetails.toAddress
  entity.escrowdetails_tokenAddress = event.params.escrowdetails.tokenAddress
  entity.escrowdetails_tokenAmount = event.params.escrowdetails.tokenAmount
  entity.escrowdetails_feeinPPM = event.params.escrowdetails.feeinPPM
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
}

export function handleEscrowReleased(event: EscrowReleasedEvent): void {
  let entity = new EscrowReleased(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.escrowId = event.params.escrowId
  entity.escrowIdStatus = event.params.escrowIdStatus
  entity.amountReleased = event.params.amountReleased
  entity.feeForSwapandBurn = event.params.feeForSwapandBurn

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
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
