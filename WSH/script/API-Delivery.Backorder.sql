set SERVEROUTPUT ON;
DECLARE
  --Standard Parameters.
  p_api_version                NUMBER;
  p_init_msg_list              VARCHAR2(30);
  p_commit                     VARCHAR2(30);

  --Parameters for WSH_DELIVERIES_PUB.Delivery_Action.   
  p_action_code                VARCHAR2(15);
  p_delivery_id                NUMBER;
  p_delivery_name              VARCHAR2(30);
  p_asg_trip_id                NUMBER;
  p_asg_trip_name              VARCHAR2(30);
  p_asg_pickup_stop_id         NUMBER;
  p_asg_pickup_loc_id          NUMBER;
  p_asg_pickup_loc_code        VARCHAR2(30);
  p_asg_pickup_arr_date        DATE;
  p_asg_pickup_dep_date        DATE;
  p_asg_dropoff_stop_id        NUMBER;
  p_asg_dropoff_loc_id         NUMBER;
  p_asg_dropoff_loc_code       VARCHAR2(30);
  p_asg_dropoff_arr_date       DATE;
  p_asg_dropoff_dep_date       DATE;
  p_sc_action_flag             VARCHAR2(10);
  p_sc_close_trip_flag         VARCHAR2(10);
  p_sc_create_bol_flag         VARCHAR2(10);
  p_sc_stage_del_flag          VARCHAR2(10);
  p_sc_trip_ship_method        VARCHAR2(30);
  p_sc_actual_dep_date         VARCHAR2(30);
  p_sc_report_set_id           NUMBER;
  p_sc_report_set_name         VARCHAR2(60);
  p_wv_override_flag           VARCHAR2(10);
  p_sc_defer_interface_flag    VARCHAR2(1);
  x_trip_id                    VARCHAR2(30);
  x_trip_name                  VARCHAR2(30);

  --out parameters   
  x_return_status              VARCHAR2(10);
  x_msg_count                  NUMBER;
  x_msg_data                   VARCHAR2(2000);
  x_msg_details                VARCHAR2(3000);
  x_msg_summary                VARCHAR2(3000);

  -- Handle exceptions   
  vApiErrorException           EXCEPTION;
  
  procedure print_out(msg varchar2) is
  begin
    DBMS_OUTPUT.PUT_LINE (msg);
  end;
  
BEGIN

  -- Initialize return status

  x_return_status := WSH_UTIL_CORE.G_RET_STS_SUCCESS;

  -- Call this procedure to initialize applications parameters

  xxfr_pck_variaveis_ambiente.inicializar('ONT', 'UO_FRISIA'); 
  fnd_msg_pub.initialize;

  -- Values for Ship Confirming the delivery

  p_action_code                 := 'CONFIRM';  -- The action code for ship confirm
  p_delivery_id                 := 204021;     -- The delivery that needs to be confirmed
  p_sc_action_flag              := 'S';        -- Backorder quantity.
  p_sc_close_trip_flag          := 'N';        -- Close the trip after ship confirm
  p_sc_defer_interface_flag     := 'N';
  p_sc_stage_del_flag           := 'N';
  --p_sc_trip_ship_method         := 'DHL';      -- The ship method code

  -- Call to WSH_DELIVERIES_PUB.Delivery_Action.
  WSH_DELIVERIES_PUB.Delivery_Action(
    p_api_version_number         => 1.0,
    p_init_msg_list              => p_init_msg_list,
    x_return_status              => x_return_status,
    x_msg_count                  => x_msg_count,
    x_msg_data                   => x_msg_data,
    p_action_code                => p_action_code,
    p_delivery_id                => p_delivery_id,
    p_delivery_name              => p_delivery_name,
    p_asg_trip_id                => p_asg_trip_id,
    p_asg_trip_name              => p_asg_trip_name,
    p_asg_pickup_stop_id         => p_asg_pickup_stop_id,
    p_asg_pickup_loc_id          => p_asg_pickup_loc_id,
    p_asg_pickup_loc_code        => p_asg_pickup_loc_code,
    p_asg_pickup_arr_date        => p_asg_pickup_arr_date,
    p_asg_pickup_dep_date        => p_asg_pickup_dep_date,
    p_asg_dropoff_stop_id        => p_asg_dropoff_stop_id,
    p_asg_dropoff_loc_id         => p_asg_dropoff_loc_id,
    p_asg_dropoff_loc_code       => p_asg_dropoff_loc_code,
    p_asg_dropoff_arr_date       => p_asg_dropoff_arr_date,
    p_asg_dropoff_dep_date       => p_asg_dropoff_dep_date,
    p_sc_action_flag             => p_sc_action_flag,
    p_sc_close_trip_flag         => p_sc_close_trip_flag,
    p_sc_create_bol_flag         => p_sc_create_bol_flag,
    p_sc_stage_del_flag          => p_sc_stage_del_flag,
    p_sc_trip_ship_method        => p_sc_trip_ship_method,
    p_sc_actual_dep_date         => p_sc_actual_dep_date,
    p_sc_report_set_id           => p_sc_report_set_id,
    p_sc_report_set_name         => p_sc_report_set_name,
    p_wv_override_flag           => p_wv_override_flag,
    p_sc_defer_interface_flag    => p_sc_defer_interface_flag  ,         
    x_trip_id                    => x_trip_id,
    x_trip_name                  => x_trip_name
  );

  print_out('  Saida:'||x_return_status);
  for i in 1 .. x_msg_count loop
    x_msg_data := fnd_msg_pub.get( 
      p_msg_index => i, 
      p_encoded   => 'F'
    );
    print_out('  '|| i|| ') '|| x_msg_data);
  end loop;
EXCEPTION
  WHEN vApiErrorException
  THEN
      WSH_UTIL_CORE.get_messages('Y', x_msg_summary, x_msg_details,x_msg_count);
      IF x_msg_count > 1
      THEN
          x_msg_data := x_msg_summary || x_msg_details;
          DBMS_OUTPUT.PUT_LINE('Message Data : '||x_msg_data);
      ELSE
          x_msg_data := x_msg_summary;
          DBMS_OUTPUT.PUT_LINE('Message Data : '||x_msg_data);
      END IF; 
  WHEN OTHERS
  THEN
      DBMS_OUTPUT.PUT_LINE('Unexpected Error: '||SQLERRM);

END;  
/