import {
  assert,
  describe,
  test,
  clearStore,
  beforeAll,
  afterAll
} from "matchstick-as/assembly/index"
import { BigInt, Address } from "@graphprotocol/graph-ts"
import { AI_DisputeClaimed } from "../generated/schema"
import { AI_DisputeClaimed as AI_DisputeClaimedEvent } from "../generated/EscrowPayment/EscrowPayment"
import { handleAI_DisputeClaimed } from "../src/escrow-payment"
import { createAI_DisputeClaimedEvent } from "./escrow-payment-utils"

// Tests structure (matchstick-as >=0.5.0)
// https://thegraph.com/docs/en/developer/matchstick/#tests-structure-0-5-0

describe("Describe entity assertions", () => {
  beforeAll(() => {
    let escrowId = BigInt.fromI32(234)
    let escrowIdStatus = 123
    let newAI_DisputeClaimedEvent = createAI_DisputeClaimedEvent(
      escrowId,
      escrowIdStatus
    )
    handleAI_DisputeClaimed(newAI_DisputeClaimedEvent)
  })

  afterAll(() => {
    clearStore()
  })

  // For more test scenarios, see:
  // https://thegraph.com/docs/en/developer/matchstick/#write-a-unit-test

  test("AI_DisputeClaimed created and stored", () => {
    assert.entityCount("AI_DisputeClaimed", 1)

    // 0xa16081f360e3847006db660bae1c6d1b2e17ec2a is the default address used in newMockEvent() function
    assert.fieldEquals(
      "AI_DisputeClaimed",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "escrowId",
      "234"
    )
    assert.fieldEquals(
      "AI_DisputeClaimed",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "escrowIdStatus",
      "123"
    )

    // More assert options:
    // https://thegraph.com/docs/en/developer/matchstick/#asserts
  })
})
