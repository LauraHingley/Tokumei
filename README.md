# Tokumei

**A tiny but MIGHTY Elixir webframework**

The Tokumei framework is a collection of focued independent libraries.
They were developed from experiments into developing a few applications in Elixir.

Inspiration has come from a variety of places but particularly [Hanami](http://hanamirb.org/) from the Ruby community is woth mentioning.

Tokumei is built on top of [Raxx](https://github.com/CrowdHailer/raxx), because it shares the same goal to preserve the simple message semantics of the Request/Response cycle.

# Development is in [/app](https://github.com/CrowdHailer/Tokumei/tree/master/app).

-------------------------------------------------------------------------------

The rest of this repo consists of experiments in progress.

-------------------------------------------------------------------------------

This repo exists to experiment with code that does not belong in raxx.
Raxx should be limited to behaviour that can be found in a http sepcification.

Useful libraries would include:
- sessions
- flash messages
- form validation
- templating
- js compilation
- gateways
- asset serving
- security (although for prudence some of this will be in the interface/server)

## Dreamcoding

### Routing

Two ways to consider routing.
- Router to Controllers that expect a mix of Elixir and Request objects
- As a tree splitting request objects.

Many modules implementing the `handle_request` function are an example of the second.
Rails etc implements the first, I have not previously been interested in the first but I think it is worth investigating.



benefits
- easier to read

costs
- complication by introduction of macro
- controller should be domain specific but more often than not will need http specific info from request.
  alternative is to pass only request and then re read path

### Forms

With input coercion/validation there is a shape of data that is expected to an action.
coercion is the changing of individual fields from there transport representation to a program type. `string -> email`. Validation is the checking that the form is correct as far as an outside caller is concerned, password_confirmation and the like.
Coercion can be of the form string to string or to a rich type.

A form object is a mapping from an in browser form. It may map nicely to the domain data it may not. Lets assume that it does. i.e. fields will always be sent and if they are withheld we can assume that is deliberate.


```elixir
defmodule SignUpForm do
  import WebForm.Fields

  def validator do
    [
      first_name: name_field(blank: {:error, :required})
      last_name: name_field(blank: {:ok, nil})
      email: email_field(blank: %NullEmail{{}})
      avatar: file_field(max_size: 30_000, empty: {:ok, nil})
      username: string_field(max_size: 30_000, blank: {:error, :required})
      country: field(&country_from_alpha2/1, blank: {:error, :requred})
    ]
  end

  def validate(form) do
    WebForm.validate(validator, form)
  end

  defp name_field(required) do
    string_field(pattern: ~r/[a-z]/i, min_length: 3, max_length: 26)
  end
end
```

```elixir
defmodule Router do
  use SomeRouter

  def handle_request(%{path: ["sign-up"], method: :POST, body: %{"sign-up" => form}}, %{accounts: accounts}) do
    OK.with do
      data <- SignUpForm.validate(form)
      user <- accounts.sign_up(data)
      {:ok, redirect("/", success: "Welcome")}
    else
      %InvalidForm{form: form, errors: errors} ->
        bad_request(sign_up_page(form, errors))
      %EmailTaken{action: data, extra: email_address} ->
        conflict(sign_up_page(data, %{email: "already taken"}))
    end
  end
end
```
- HTTP action handlers should wait for any calls they need before they response.
This is not a usecase where the message monad makes sense
- Maybe hardcode services which are then passed to domain


```elixir
defmodule MyApp.Web do
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(Ace.HTTP, [MyApp.Web.Router, [port: 8080, name: MyApp.Web]])
    ]

    opts = [strategy: :one_for_one, name: MyApp.Web.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```


## Usage

#### Running with Mix

```
# vagrant@development

cd /vagrant/server
mix deps.get
iex -S mix
```

Visit [localhost:8080](localhost:8080)

#### Manually deploying a distribution

```
# vagrant@development

cd /vagrant/server
mix deps.get
mix release --env prod

scp rel/baobab/releases/0.0.1/baobab.tar.gz vagrant@<dmz ip address>:.
# Find ip following instructions below or setup static ip
# On Digital ocean user is root, add ssh key or expect password in an email.
```

```
# vagrant@dmz

ifconfig
# get private ip_address, use eth1

tar -xf baobab.tar.gz
./bin/baobab start
```

visit http://172.28.128.4:8080/3434 # substitute dmz ip.

https://medium.com/@kelseyhightower/12-fractured-apps-1080c73d481c#.6ralm99gu

#### Clustering

#### Discovery

many discovery things

- https://github.com/schlagert/bootstrap
- http://stackoverflow.com/questions/78826/erlang-multicast
- https://github.com/bitwalker/swarm
- https://github.com/edevil/elixir_kubernetes_cluster
- https://en.wikipedia.org/wiki/Zero-configuration_networking
- https://github.com/Licenser/erlang-mdns-server
- https://github.com/harmon25/sonex/blob/master/lib/sonex/discovery.ex

## Roadmap

A long list of things that I need to do to make cloud native applications easier.

- [x] Setup vagrant for this project.
- [x] Build releases with [distillery](https://github.com/bitwalker/distillery)
- [x] Create a production with vagrant.
- [x] Organise DO/GCP credentials
- [x] Work out how to debug in a vm node.
- [ ] Integrate with provisioning resources, looks like kuberneties, look at katacoda.
- [ ] check nomad for example of cloud integration, [which to choose](https://thehftguy.wordpress.com/2016/06/08/choosing-a-cloud-provider-amazon-aws-ec2-vs-google-compute-engine-vs-microsoft-azure-vs-ibm-softlayer-vs-linode-vs-digitalocean-vs-ovh-vs-hertzner/) DO -> GCP -> (IBM machine images)
- [ ] Setup [DMZ](http://www.erlang-factory.com/static/upload/media/144975595943066francescocesarinieflberlin2015.pdf#14) network area, certain releases from umbrella app. [DO floating ips](https://www.digitalocean.com/products/networking/) to load balancers. make each of [DO server setups](https://www.digitalocean.com/community/tutorials/5-common-server-setups-for-your-web-application)
- [ ] Programmable load balancing from DMZ webservers to application server. One example would be a riak core ring or phoenix presence regestration.

- [real world elixir deployment](https://www.youtube.com/watch?v=H686MDn4Lo8)
- [load balancing websockets](http://www.oxagile.com/company/blog/load-balancing-of-websocket-connections/)
- [Elixir deployment tools](https://elixirforum.com/t/elixir-deployment-tools-general-discussion-blog-posts-wiki/827)
- [Elixir and Erlang cluster](http://bitwalker.org/posts/2016-08-04-clustering-in-kubernetes/)
- [elixir and kuberneties](https://substance.brpx.com/clustering-elixir-nodes-on-kubernetes-e85d0c26b0cf#.6o9fjoxrw)

The first step is to get Buildroot running on the platform. The next is to take a look at one of our system images and modify it based on what you learned about with Buildroot.

: Yes, while Nerves could in theory use other Linux image builders, right now Buildroot is the only one we're supporting. Buildroot has generic x86_64 images that probably get close to what you need. Our root filesystems are all read-only squashfs ones. "Cross-compilation" will sound a little strange since you're on x86_64 already, but the C library that we're using will probably be slightly different so it's still needed.
3:48 Also, we do actually supply an x86_64 cross-compiler that targets the MUSL C library that can be used on OSX, PC Linux, and RPi. I added it a while back when someone else asked me about running on a server. I haven't used it, though. You can find it under the v0.7.1 release at https://github.com/nerves-project/toolchains/releases/.

^Nerves chat

## Mission
look at phoenix mission silde from 2014

- Encourage domain modelling
- Immutable data history
- independent clients. offline first sharded DB,
- MoSQL

## Names
Anvil, (Anonimous/kernal)
Nimbus, cloud native

Suggestions for securing a DO node.

@crowdhailer I would make sure to have a separate (non-root) user running the Elixir application, at least `ufw` installed to close all other ports than 80/22, and set `PermitRootLogin no` in `/etc/ssh/sshd_config`
Those three things are some quick wins with regards to security of a web app

[setting up a server](https://www.digitalocean.com/community/tutorials/initial-server-setup-with-ubuntu-16-04)
## Glossary

Each machine type has a different release (grouping of applications, assembly, cohort)
## Notes
Instructions on setting up Cowboy are reasonably limited.
Some of these resources are helpful.

- [Cowboy elixir example](https://github.com/IdahoEv/cowboy-elixir-example/blob/master/lib/dynamic_page_handler.ex)
- [Elixir rest with cowboy](http://www.jonasrichard.com/2016/02/elixir-rest-with-cowboy.html)

The plug documentation is also lacking.
It seams only to exist to serve Phoenix, however these articles are helpful.

- [Building a web framework from scratch in Elixir](https://codewords.recurse.com/issues/five/building-a-web-framework-from-scratch-in-elixir)
- [Getting started with Plug in Elixir](http://www.brianstorti.com/getting-started-with-plug-elixir/)

there is no such thing as stateless it's just someone elses problem. we should embrace the state own the state.
https://www.youtube.com/watch?v=DRK7WYNh6AA

async is the constraints of the system in fact the constraints of reality

http://adrianmarriott.net/logosroot/papers/LifeBeyondTxns.pdf
