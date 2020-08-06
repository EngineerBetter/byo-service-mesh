# Bring your own service mesh to Cloud Foundry (using Consul)

Deploy a [Consul](https://www.consul.io/) control plane and service mesh on top of any Cloud Foundry deployment _without being a platform operator_.

> For additional information, please see the [BYO Service Mesh to Cloud Foundry](https://www.engineerbetter.com/blog/byo-service-mesh/) post on the Engineer Better blog.

## Binaries
To deploy the service mesh, you will need the following binaries in the `bin/` directory:
- `consul` ([v1.8.0](https://releases.hashicorp.com/consul/1.8.1/consul_1.8.1_linux_amd64.zip))
- `envoy` ([v1.14.2](https://www.getenvoy.io/))
- `hotrod` ([v1.18.1](https://github.com/jaegertracing/jaeger/tree/v1.18.1/examples/hotrod))

## Consul servers
To deploy the Consul servers, run:
```bash
# Create app + network policies to allow server instances to communicate
cf create-app consul-server
cf add-network-policy consul-server consul-server --port 8300-8302 --protocol tcp
cf add-network-policy consul-server consul-server --port 8301-8302 --protocol udp

cf push consul-server
```
> Note: rolling deploys to not work for current configuration of `consul-server`)

This will push 3 instances of the Consul server including running the UI. To allow this to be viewed externally, either include an additional route in `manifest.yml` or `cf map-route` after pushing.

## Applications
Applications can be added to the service mesh by running two sidecars:
* `consul-agent` - communicates with Consul servers to register and configure proxy
* `consul-proxy` - Envoy proxy managed by Consul agent

This repo uses a convention of `consul.d/<application-name>/` for storing Consul specific configuration for that application. In addition to this, services within that configuration should also use the same name as the application. This allows us to use `-sidecar-for $(echo "$VCAP_APPLICATION" | jq -r '.name')` as the startup command for the proxy which can be generically re-used across all applications.

## Network policies
All applications that should be able to communicate should have a `label` added to their metadata of `service-mesh: true`. This is then read by the `network-policies.rb` script which finds all applications labelled as in the service mesh and ensures that they are able to communicate freely within the `8000-9000` port range. This range is deliberately broad as we can use Consul intentions to control network access rather than Cloud Foundry network policies. All proxy, metrics etc. ports should be placed in this range.