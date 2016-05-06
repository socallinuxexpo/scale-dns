DNS
===

This repo is intended to serve as the canonical source of truth for DNS records
during the transition to a hosted DNS service.

Currently, SCALE has these domains with identical records:

* `socallinuxexpo.org` [primary]
* `socallinuxexpo.net`
* `socallinuxexpo.com`
* `southerncalifornialinuxexpo.org`
* `southerncalifornialinuxexpo.net`
* `southerncalifornialinuxexpo.com`

While, LinuxFests has these domains with identical records:

* `linuxfests.org` [primary]
* `linuxfests.net`
* `linuxfests.com`

At some point in the relatively near future (timescale of months), it would be
worthwhile to have a technical discussion to determine if duplicate records
across domains continues to be a requirement. In the interim, it is more
expedient to preserve the current structure rather potentially blocking DNS
migration on a technical decision that involves many stake holders.

route53
---

Amazon's [route53](https://aws.amazon.com/route53/) has been selected as the
interim solution largely due to a few individuals existing familiarity with the
service and a utility named [cli53](https://github.com/barnybug/cli53), which
provides for easy import and export of bind format zone files.

While [bind](https://www.isc.org/downloads/bind/) makes it relatively easy to
ensure the exact same set of records is present in multiple zones by reusing
the same zone file.  This requires some additional handling with a hosted
service that does not allow direct manipulation of it's configuration files.

Therefore, to prevent the independent zones from drifting out of sync, these
zones are to be considered authoritative:

* `socallinuxexpo.org`
* `linuxfests.org`

Any record changes (create/update/replace/delete) should be made in
"authoritative" zone first then replicated to the "shadow" zones.


cli53
---

`cli53` requires a set of aws access keys to in order to operate.  These may be
set as environment variables rather than input into a configuration file. Eg.

    export AWS_ACCESS_KEY_ID=<...>
    export AWS_SECRET_ACCESS_KEY=<...>

Please note that many of the command examples below will fail if multiple zones
for the same domain have been created in the same AWS account as the domain
name would no long be a unique identifier.  Please be careful.

Initial Ingest
---

The initial zone creation and import of records.  __This should not be
recreated in the main scale aws account.__

    make
    for tld in org net com; do
        ./cli53-linux-amd64 create socallinuxexpo.$tld
        ./cli53-linux-amd64 import -d --file exports/actusa-socallinuxexpo-export.zone socallinuxexpo.$tld
    done

Zone Sync
---

Replicate records from `socallinuxexpo.org` to the "shadow" zones.  This should
be done if recorders were modified via the API or the AWS console.  Changes
should manually replicated and committed back to this repo.  This is becomes a
burdensome task, this may be automated in the future.

Note that `cli53 import` will ignore `NS` and `SOA` records by default but not
the zone `$ORIGIN`.

    git pull origin master
    make
    ./cli53-linux-amd64 export socallinuxexpo.org > zones/scale/socallinuxexpo.org.zone
    git diff
    git commit -m "add A records for foobar" socallinuxexpo.org.zone
    git push

    sed -e 's/^$ORIGIN socallinuxexpo.org.//' socallinuxexpo.org.zone > socallinuxexpo.generic.zone
    for tld in net com; do
        ./cli53-linux-amd64 import -d --replace --file socallinuxexpo.generic.zone socallinuxexpo.$tld
    done

Export All
---

Dump all zones and sanity check that the records are in sync.

    make
    for tld in org net com; do
        ./cli53-linux-amd64 export socallinuxexpo.$tld > zones/scale/socallinuxexpo.${tld}.zone
    done
    diff -u socallinuxexpo.org.zone socallinuxexpo.net.zone
    diff -u socallinuxexpo.org.zone socallinuxexpo.com.zone

Import All
---

__This will delete any record in the zone that are not present in the in the
import set.__

    make
    sed -e 's/^$ORIGIN socallinuxexpo.org.//' socallinuxexpo.org.zone > zones/scale/socallinuxexpo.generic.zone
    for tld in org net com; do
        ./cli53-linux-amd64 import -d --replace --file socallinuxexpo.generic.zone socallinuxexpo.$tld
    done
