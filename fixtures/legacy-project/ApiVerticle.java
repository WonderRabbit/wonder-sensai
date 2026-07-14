import io.vertx.core.AbstractVerticle;
import io.vertx.ext.web.Router;

public final class ApiVerticle extends AbstractVerticle {
  @Override
  public void start() {
    Router router = Router.router(vertx);
    router.get("/api/orders").handler(context ->
      vertx.eventBus().request("orders.list", "all", reply -> context.response().setStatusCode(200).end(reply.result().body().toString()))
    );
  }
}
