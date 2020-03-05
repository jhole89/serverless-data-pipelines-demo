# Lambda Triggers

This sub-module contains lambda functions that are used as unsupported in-betweens to trigger 
Terraform/AWS services that cannot be triggered directly via resource/ARN reference and
must be done via a aws-sdk call.  We house them here as they are considered "infrastructure"
code rather than "application" code, and should Terraform support triggering these services
directly in the future, we should move to using these supported implementations.
