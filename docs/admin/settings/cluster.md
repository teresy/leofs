# Cluster Settings

This document outlines the various configuration items to keep in mind when planning a LeoFS system's cluster, and this documentation leads you to be able to configure its cluster when planning and launching it correctly.


## Prior Knowledge

LeoFS adopts [eventual consistency](https://en.wikipedia.org/wiki/Eventual_consistency) of the consistency model; it takes priority over AP *(Availability and Partition tolerance)* over C *(consistency)* which depends on [CAP theorem](https://en.wikipedia.org/wiki/CAP_theorem).

To keep the consistency of objects eventually, LeoFS delivers the replication and recovery feature to automatically fix consistency of objects. You can configure the consistency level of a LeoFS system, and it is affected by the configuration.


### How to Keep RING's Consistency
#### Case 1: Both LeoManager nodes are unavailable

If both LeoManager nodes are unavailable, LeoStorage and LeoGateway nodes don't update the RING to keep its consistency into the LeoFS system.

#### Case 2: One LeoManager node is unavailable

If a LeoManager node is unavailable, LeoFS can update the RING, and synchronize it with the LeoFS' system eventually. After restarting another LeoManager node, LeoManager automatically synchronizes the RING between the manager nodes.


## Consistency Level

Configure the consistency level of a LeoFS system at <a href="https://github.com/leo-project/leofs/blob/master/apps/leo_manager/priv/leo_manager_0.conf" target="_blank">LeoManager's configuration file - leo_manager_0.conf</a>. You need to carefully configure the consistency level because it is not able to change some items after starting the system.


There are four configuration items at <a href="https://github.com/leo-project/leofs/blob/master/apps/leo_manager/priv/leo_manager_0.conf" target="_blank">`leo_manager_0.conf`</a>, items of which have a great impact on **data availability** and **storage performance**.

| Item                              | Abbr | Modifiable | Default | Description |
|-----------------------------------|:----:|------------|---------|---|
| `consistency.num_of_replicas`     | n    | No         | 1       | A number of replicas |
| `consistency.write`               | w    | Yes        | 1       | A number of replicas needed for a successful WRITE operation  |
| `consistency.read`                | r    | Yes        | 1       | A number of replicas needed for a successful READ operation   |
| `consistency.delete`              | d    | Yes        | 1       | A number of replicas needed for a successful DELETE operation |
| `consistency.rack_aware_replicas` |      | No         | 0       | A number of rack-aware replicas |


### Data Availability of Consistency Level

This document delivers the relationship of `data availability` and `configuration level` as below:

| Data Availability | Configuration Level   | Description |
|-------------------|-----------------------|-------------|
| Extremely Low     | n=2, r=1<br/>w=1, d=1 | Data can not be acquired even if two nodes goes down *(for personal use)*|
| Low               | n=3, r=1<br/>w=1, d=1 | Low data consistency|
| Middle(1)         | n=3, r=1<br/>w=2, d=2 | Typical settings |
| Middle(2)         | n=3, r=2<br/>w=2, d=2 | High data consistency than `Middle(1)` |
| High              | n=3, r=2<br/>w=3, d=3 | Data can not be input and removed even if one node goes down |
| Extremely High    | n=3, r=3<br/>w=3, d=3 | Data can not be acquired even if one node goes down *(can not be recommended)*|

!!! Warning "Warning: Rebalance with Extremely High Settings"
    While rebalance is on-going, PUT/DELETE use an new RING and GET/HEAD use an old RING. That said, if any updates happen on existing objects then there can be inconsistent objects from the old RING perspective however thanks to the inherent nature of the consistent hashing, almost replicas keep staying at the same position so it should not be problem while operating LeoFS in a typical(Other than `Extremely High`) consistency level. But if you operate LeoFS in `Extremely High` then GET/HEAD to the existing object may fail during the rebalance process. If that is the case then you may be able to use `update-consistency-level` to lower the consistency level temporarily. Don't forget to set it back to the original setting once the rebalance finishes.

### How To Change Consistency Level

You can change `consistency.write `, `consistency.read` and `consistency.delete` of the consistency level that you use the `leofs-adm update-consistency-level` command, but you cannot update `num_of_replicas` and `rack_aware_replicas`.

```bash
## Changes the consistency level to [w:2, d:2, r:1]
$ leofs-adm update-consistency-level 2 2 1

```

## Rack Awareness

LeoFS provides rack-awareness replication for more availability in case you can control which racks (or any type of availability domains like network switches) your cluster belongs to. With the rack-awareness replication enabled, it can ensure that your files will be stored across different racks or network switches to minimise the risk of losing data.

### Configurations
You would have to configure the below two items in order to enable rack-awareness replication.

- `replication.rack_awareness.rack_id` in `leo_storage.conf`
    - it enables you to specify which rack LeoStorage belongs
- `consistency.rack_aware_replicas` in `leo_manager.conf`
    - it enables you to specify how many racks each file will be replicated

### Example
Let's say that we try to create a cluster with

- 6 storage nodes (node[1-6])
- 2 physical racks (rack[1-2])
- 2 replicas and each replica should belong to a different rack

Then set the configurations as followings

- `replication.rack_awareness.rack_id` on each `leo_storage.conf`
    - node1: `replication.rack_awareness.rack_id = rack1`
    - node2: `replication.rack_awareness.rack_id = rack1`
    - node3: `replication.rack_awareness.rack_id = rack1`
    - node4: `replication.rack_awareness.rack_id = rack2`
    - node5: `replication.rack_awareness.rack_id = rack2`
    - node6: `replication.rack_awareness.rack_id = rack2`
- `consistency.rack_aware_replicas = 2` on `leo_manager.conf`

### Limitations
There are several limitations for rack-awareness replication on LeoFS with 1.4.x so be careful those limitations described below if you'd like to use rack-awareness replication on your production system.

- Files will not evenly distributed across the cluster if each rack has diffrent number of servers.
- Files may not evenly distributed across the cluster even if each rack has the same number of servers because the current distribution logic is so naive.
- PUT/DELETE with rack-awareness has not been supported yet. (Ex. With n=3, w=2, d=2 consistency setting, PUT/DELETE with rack-awareness tries to replicate files at least two servers and each server belongs to a different rack.)

The first/second limitations will be solved by dynamic vnode allocation which we plan to implement in 2.x release and regarding the last one, there is still no plan to implement it however we are willing to prioritize if there are lots of demands from our community.

## Related Links

* [For Administrators / Settings / LeoManager Settings](leo_manager.md)
* [For Administrators / Settings / LeoStorage Settings](leo_storage.md)
