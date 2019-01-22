TODO upload text to S3
TODO make instance read from S3 (using CLI)
TODO restart an instance on failure (4 min outage OK)
TODO restrict a bucket to a VCP, single user write (create user!) and read acc. to single instance
TODO make lambda function restart instance on change to bucket











---
TODO make use of the following Kubernetes networking notes
   A kub cluster is a set of machines on a private network running nodes (controllers and workers). Each worker maintains a collection of pods (sets of containers with shared networking/disk, basically virtual computers with a set of services).
   In any private k8s network you have IPs for nodes ('actual' machines), Pods and Services (faked, using iptables).
   To expose them externally, use NodePort/LoadBalancer/Ingress

TODO do more: https://www.whizlabs.com/
 Esp. the security certificates

TODO FIXME If provisioner fails, EC2 instances are not tainted in TF (presumably because only the fake
null resource we generate actually fails to provision - those were added to ensure the Nix config is
always repushed when it has changed - alternative way of doing that?).
NOTE this is only a problem if the provisioner *breaks* the instance, e.g. by filling the harddrive

TODO IAM group/role/policy (e.g. create S3 bucket and give access to single instance)

TODO NOW S3 bucket creation/addition

TODO redis cluster (either ElastiCache or EC2+NixOS)

TODO RDS instance + user + database

TODO setup custom VPC with private subnet?

TODO test AWS SNS?

TODO NOW extend Docker/NixOS/EC2 to build a static set of containers
Push results to ECS (for now)
Extend testDocker to also install Packer+Terraform, build images, and push to ECS
     pkgs.packer
     pkgs.terraform

TODO Gitlab + Pipeline that builds docker images (isolated from Internet to assure pure functin of commit)
 + orchestration in k8s/EKS or Nomad/NixOS/EC2


TODO get TF to boot EKS cluster and run standard containers in there (e.g. consul cluster)

TODO NixOS machine with docker + standard consul image
E.g. as above, then run:
  docker pull consul
  docker run -t -i consul agent -bootstrap-expect=1 -server

TODO use free category (final encoding) to pass chain of pure functions (e.g. for log pipelines)

TODO build custom Docker images using NixOS (preferably driven by expressions, similar to our NixOS provisioning)
  See: https://nixos.wiki/wiki/Docker

TODO Consul cluster based on Docker+Kubernetes?
TODO more generally: config/launch containers in EKS, or functions in Lambda as an alternative to NixOS/EC2

TODO use packer to build AMIs/Docker containers

TODO [NOTE pinNixPkgs] pin nixpkgs on the machines/AMI?
See:
   http://www.haskellforall.com/2018/08/nixos-in-production.html

TODO configurable EC2 instance type/size

TODO something like
   https://itnext.io/building-a-kubernetes-hybrid-cloud-with-terraform-fe15164b35fb

TODO instead of using Free, could the user just write a function of the type and dictionary?
E.g. the framework provides the Applicative/whatever.

TODO break up cloud.av/better interface
   * Break up cloud.av into "one file per let" convention
   * Make sure all comments are on top of file, and we can run the formatter :)
       https://github.com/dhall-lang/dhall-haskell/issues/145
   * The user CLI should take a single expression (any .av file in CWD, balking if >1) by default
   * Use lambda abstraction to hide internals: see [Evaluator Protocol] and [Safe attributes]

TODO simple test suite
Should take
   [{norosExpr:Text,expectedEndpoint:Text,timeout:Natural}]
deploys a bunch of expressions in sequence and verifies the
given URL comes up within the given time.
Arguably: Separate things that can be tested localy/on-cloud (e.g. requiring AWS creds or similar).
  Should allow CIs to run exactly the tests they have credentials for.
Note some 'test' fields sketched above.

TODO restore S3/etc

