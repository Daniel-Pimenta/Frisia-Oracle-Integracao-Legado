create or replace function XXFR_FN_INV_QUANTITY_TREE (
  p_inventory_item_id number,
  p_organization_id   number
) return number is

  l_api_return_status varchar2(1);
  l_qty_oh            number;
  l_qty_res_oh        number;
  l_qty_res           number;
  l_qty_sug           number;
  l_qty_att           number;
  l_qty_atr           number;
  l_msg_count         number;
  l_msg_data          varchar2(1000);
  l_subinv            varchar2(10);
  l_organization_id   number;
  l_inventory_item_id number;

begin
  apps.inv_quantity_tree_grp.clear_quantity_cache;
  --l_subinv := 'PAE';
  apps.inv_quantity_tree_pub.query_quantities (
    p_api_version_number    => 1.0
    , p_init_msg_lst        => apps.fnd_api.g_false
    , x_return_status       => l_api_return_status
    , x_msg_count           => l_msg_count
    , x_msg_data            => l_msg_data
    , p_organization_id     => p_organization_id
    , p_inventory_item_id   => p_inventory_item_id
    , p_tree_mode           => apps.inv_quantity_tree_pub.g_transaction_mode
    , p_onhand_source       => 3
    , p_is_revision_control => false
    , p_is_lot_control      => false
    , p_is_serial_control   => false
    , p_revision            => null
    , p_lot_number          => null --- PODERÁ SER COLOCADO SE NECESSÁRIO
    , p_subinventory_code   => l_subinv
    , p_locator_id          => null -- PODERÁ SER COLOCADO SE NECESSÁRIO
    , x_qoh                 => l_qty_oh
    , x_rqoh                => l_qty_res_oh
    , x_qr                  => l_qty_res
    , x_qs                  => l_qty_sug
    , x_att                 => l_qty_att
    , x_atr                 => l_qty_atr 
  );
  return nvl(l_qty_oh,0);
end XXFR_FN_INV_QUANTITY_TREE;
/