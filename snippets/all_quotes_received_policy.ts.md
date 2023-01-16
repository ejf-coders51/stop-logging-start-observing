```
import { EventBus, EventResult } from "../infra/event_bus"
import { AllQuotesReceived } from "./job"
import { getMeter } from "../infra/instrumentation"
import { Logger } from "winston"
import { inspect } from "util"
import got from "got"
import { trace } from "@opentelemetry/api"

export class AllQuotesReceivedPolicy {
  constructor(private logger: Logger) {}

  registerTo(eventBus: EventBus) {
    eventBus.register<AllQuotesReceived>(AllQuotesReceived.EventName, (e) => this.allQuotesReceived(e))
  }

  async allQuotesReceived(e: AllQuotesReceived): Promise<EventResult> {
    let winner = 0
    let priceWinner = 0

    const winnerSelectionTrace = trace.getTracer("job")

    await winnerSelectionTrace.startActiveSpan("winner_selection", async (span) => {
      this.logger.info(`AllQuotesReceived ${inspect(e.payload)}`)

      const { priceFleet1, priceFleet2, priceFleet3 } = e.payload
      const prices = [priceFleet2, priceFleet3]
      priceWinner = priceFleet1

      for (const [index, price] of prices.entries()) {
        if (price < priceWinner) {
          priceWinner = price
          winner = index + 1
        }
      }
      this.logger.info(`THE WINNER IS: fleet${winner + 1}`)
      span.end()
    })

    const fleet1 = process.env.FLEET1 || "localhost:10002"
    const fleet2 = process.env.FLEET2 || "localhost:10003"
    const fleet3 = process.env.FLEET3 || "localhost:10004"
    const fleets = [fleet1, fleet2, fleet3]

    const url = `http://${fleets[winner]}/api/booking`
    const resp = await got.post(url, {})
    this.logger.debug(inspect(resp))

    getMeter()
      .createCounter("booking_total")
      .add(1, { fleet: `${winner + 1}` })

    return { ack: true }
  }
}
```
