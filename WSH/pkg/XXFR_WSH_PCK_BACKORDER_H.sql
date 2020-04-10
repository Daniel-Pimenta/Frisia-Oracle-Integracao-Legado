create or replace PACKAGE XXFR_WSH_PCK_BACKORDER AUTHID CURRENT_USER AS
  /* $Header: INVMOBOS.pls 120.0 2005/05/25 05:45:54 appldev noship $ */


  /**
    * BackOrders the Source tied to a Move Order Line.
    * <p>
    * The API is responsible for Backordering the Source tied to the Move Order Line.
    * Before Backordering the Soure, all the Allocations for the Move Order Line are
    * deleted. For a WMS Organization, the Tasks should not be Active or Loaded.
    * <p>
    * The Backordered Source (either Sales Order or Job/Schedule) is available for
    * Re-Release again.
    * <p>
    * The API commits at the end if there is no error.
    * <p>
    * @param p_line_id        Move Order Line ID
    * @param x_return_status  Return Status of the API
    * @param x_msg_count      Message Count in Message Stack
    * @param x_msg_data       Message Data if Message Count is 1.
    */
  PROCEDURE backorder(
    p_line_id       IN            NUMBER,
    x_return_status OUT NOCOPY    VARCHAR2,
    x_msg_count     OUT NOCOPY    NUMBER,
    x_msg_data      OUT NOCOPY    VARCHAR2
  );

  /**
    * Deletes the Details tied to a Move Order Line.
    * <p>
    * The API is responsible for deleting an Allocation of a Move Order Line.
    * <p>
    * Before Deleting the Allocation, if the Allocation has a Reservation tied to it, it
    * decrements the Reserved Qty and Detailed Qty in the Reservation. <br>
    * For an ATO Item, if the profile WSH_RETAIN_ATO_RESERVATIONS is set to Y, then the
    * Reservation Qty is not changed. Only the Detailed Qty is affected.
    * <p>
    * @param p_transaction_temp_id  Transaction Temp ID
    * @param p_move_order_line_id   Move Order Line ID
    * @param p_reservation_id       Reservation ID
    * @param p_transaction_quantity Transaction Qty
    * @param p_primary_trx_qty      Primary Transaction Qty
    * @param x_return_status        Return Status of the API
    * @param x_msg_count            Message Count in Message Stack
    * @param x_msg_data             Message Data if Message Count is 1.
    */
  PROCEDURE delete_details(
    p_transaction_temp_id  IN            NUMBER
  , p_move_order_line_id   IN            NUMBER
  , p_reservation_id       IN            NUMBER
  , p_transaction_quantity IN            NUMBER
  , p_primary_trx_qty      IN            NUMBER
  , p_secondary_trx_qty    IN            NUMBER     -- INVCONV
  , x_return_status        OUT NOCOPY    VARCHAR2
  , x_msg_count            OUT NOCOPY    NUMBER
  , x_msg_data             OUT NOCOPY    VARCHAR2
  );

END xxfr_wsh_pck_backorder;
/