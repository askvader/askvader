 Alternatives:
   * Automatic
     - Let TF generate keys (using external provider?) and put keys in state
     - Use S3/GCS backends with SS encryption (unless you're an individual)
   * Manual
     - Provide public key to TF in standard location (where?)
  -- FIXME set default sec group to allow all inbound on 80+22 (for now)
  --
  -- Design note:
 * Core idea of AV is "take a single expression and realize it"
 * As far as state is used (e.g. by TF) this should be hidden in the backend (AWS, GCE) by default
 * AV should use standard local paths for access keys to cloud by default (e.g. ~/.aws/credentials)
   The machine running AV is essentially granted temporary access to the AWS account using these
   credentials. To protect the top level: use 2-factor auth etc.
 * For EC2 instances the story is more complex: AWS maintains public keys (KeyPair) and copies
   them to the instance upon launch. The only way to withdraw these keys is to stop the instance
   and modify the disk, or to terminate and replace the instances.
     "Solution 0" dev mode: AV uses a key pair provided by caller for everything.
       Anybody with this pair have full access (including access to the AWS credentials
       as these can be accessible from the instance?).
     "Solution 1" prod mode:
       TF state is assumed safe (see above).
       AV generates new key for each instance and stores private keys in state.
       To (re)provision the instance, AV retrieves the key from the state.
       No external SSH access.
       Trust: holder of credentials to state backend, machine where AV/TF is running (as it is running).
  --

