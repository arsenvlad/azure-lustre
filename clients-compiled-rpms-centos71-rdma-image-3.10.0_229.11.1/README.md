# Intel Lustre 2.7 clients on CentOS 7.1 (kernel 3.10.0_229.11.1.el7.x86_64) custom/user image with RDMA drivers

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Farsenvlad%2Fazure-lustre%2Fmaster%2Fclients-centos71-rdma-image-3.10.0_229.11.1%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>
<a href="http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2Farsenvlad%2Fazure-lustre%2Fmaster%2Fclients-centos71-rdma-image-3.10.0_229.11.1%2Fazuredeploy.json" target="_blank">
    <img src="http://armviz.io/visualizebutton.png"/>
</a>

This template creates 2 or more Intel Lustre 2.7 client virtual machines using custom/user image of CentOS 7.1 with RDMA drivers and mounts an existing Intel Lustre filesystem.

* Custom/user image of CentOS 7.1 with RDMA drivers http://longliuswest.blob.core.windows.net/vhds/20150826185255-00853603622-centos71-rdma-os1.vhd
* Create a storage account in your Azure Subscription that will be used to store the custom/user image and the OS disks of the Lustre client nodes
* Create a container called "rdma" in your storage account that will contain the image VHD
* Use Azure CLI to copy the VHD to your storage account:

***

`azure storage blob copy start --source-uri "http://longliuswest.blob.core.windows.net/vhds/20150826185255-00853603622-centos71-rdma-os1.vhd" --dest-account-name "YOUR_STORAGE_ACCOUNT_NAME" --dest-account-key "YOUR_STORAGE_ACCOUNT_KEY" --dest-container "rdma"`

`azure storage blob copy show --container rdma --blob "20150826185255-00853603622-centos71-rdma-os1.vhd" -a "YOUR_STORAGE_ACCOUNT_NAME" -k "YOUR_STORAGE_ACCOUNT_KEY"`

***

* <a href="https://wiki.hpdd.intel.com/display/PUB/Why+Use+Lustre" target="_blank">Why Use Lustre?</a>
* Intel Lustre clients must be deployed into an **existing Virtual Network** that already contains operational Intel Lustre filesystem consisting of MGS (management server), MDS (metadata server), and OSS (object storage server) nodes.
* The actual Lustre filesystem is deployed via the solution template from Azure Marketplace <a href="https://azure.microsoft.com/en-us/marketplace/partners/intel/" target="_blank">Intel Cloud Edition for Lustre* Software - Eval</a>
* When deploying this template, you will need to provide the private IP address of the MGS node (e.g. 10.1.0.4) and the name of the filesystem that was created when Lustre servers were deployed (e.g. scratch)
* Client nodes will mount the Lustre filesystem at mount point like /mnt/FILESYSTEMNAME (e.g. /mnt/scratch)
* You can view the <a href="https://build.hpdd.intel.com/job/lustre-manual/lastSuccessfulBuild/artifact/lustre_manual.xhtml#idp5145472" target="_blank">stripe_size and stripe_count</a> of the mounted filesystem using command like "lfs getstripe /mnt/scratch"
* All of the client nodes will be deployed into the same availability-set since this is required for HPC Linux RDMA functionality over InfiniBand
* Public IP will be attached to the client0 node. That node can be accessed via SSH  [dnsNamePrefix].[region].cloudapp.azure.com.
* Intel Lustre kernel modules are dynamically compiled for the currently running kernel using instructions outlined in https://wiki.hpdd.intel.com/display/PUB/Rebuilding+the+Lustre-client+rpms+for+a+new+kernel
* <a href="https://wiki.hpdd.intel.com/display/PUB/Intel+Cloud+Edition+for+Lustre+on+Azure" target="_blank">Learn more about Intel Cloud Edition for Lustre on Azure</a>
* <a href="https://build.hpdd.intel.com/job/lustre-manual/lastSuccessfulBuild/artifact/lustre_manual.xhtml" target="_blank">Lustre Manual</a>
