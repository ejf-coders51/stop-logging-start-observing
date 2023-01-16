```
import { inspect } from "util"
import { Logger } from "winston"
import { CommandBus, CommandResult } from "../infra/local_command_bus"
import { CreateOrderCommand } from "./create_order_command"
import { Order } from "./order"
import { OrderRepository } from "./order_repository"
import { wait } from "../infra/wait"
import { Command } from "../infra/command"
import { getMeter } from "../infra/instrumentation"

export class OrderCommandHandler {
  constructor(private readonly repository: OrderRepository) {}

  registerTo(commandBus: CommandBus) {
    commandBus.register(CreateOrderCommand.CommandName, (cmd: CreateOrderCommand, logger: Logger) =>
      this.createCommand(cmd, logger)
    )
  }
  private async createCommand(cmd: CreateOrderCommand, logger: Logger): Promise<CommandResult<Order>> {
    logger.info(`Create order ${inspect(cmd)}`)

    const order = Order.create(cmd.orderId, cmd.data)
    await this.doHeavyStuff(cmd)

    await this.repository.save(order, cmd.domainTrace, logger)
    getMeter().createCounter("order_created_total").add(1)

    return { success: true, payload: order }
  }

  // private async doHeavyStuff(_cmd: Command) {
  //   await wait(500)
  // }

  private async doHeavyStuffTraced(_cmd: Command) {
    const doHeavyStuffTrace = trace.getTracer("ms-order")
    await doHeavyStuffTrace.startActiveSpan("doHeavyStuff", async (span) => {
      await wait(500)
      span.end()
    })
  }
}
```
