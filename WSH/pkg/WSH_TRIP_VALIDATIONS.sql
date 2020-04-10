create or replace PACKAGE BODY WSH_TRIP_VALIDATIONS as
/* $Header: WSHTRVLB.pls 120.18.12020000.11 2016/04/22 07:38:36 ravmamid ship $ */

--
--3509004:public api changes
PROCEDURE   user_non_updatable_columns
     (p_user_in_rec     IN WSH_TRIPS_PVT.trip_rec_type,
      p_out_rec         IN WSH_TRIPS_PVT.trip_rec_type,
      p_in_rec          IN WSH_TRIPS_GRP.TripInRecType,
      x_return_status   OUT NOCOPY    VARCHAR2);


-----------------------------------------------------------------------------
--
-- Procedure:     Check_Plan
-- Parameters:    trip_id, x_return_status
-- Description:   Checks for Plan action pre-requisites which are
--		  - at least two stops are assigned
--		  - Vehicle or Ship Method information is specified
--		  - Stop sequences are valid
--		  - If trip has vehicle information then vehicle is not over/under filled at any stop [warning]
--		  - At least one delivery is assigned to trip [warning]
--  NOTE: Planning of a trip would automatically update weight/volume
--     information for stops and deliveries if they are not already specified.
--
-----------------------------------------------------------------------------

--
G_PKG_NAME CONSTANT VARCHAR2(50) := 'WSH_TRIP_VALIDATIONS';
--
PROCEDURE Check_Plan ( p_trip_id 		IN  NUMBER,
		       x_return_status 		OUT NOCOPY  VARCHAR2,
                       p_caller                 IN      VARCHAR2) IS

CURSOR stops_exist IS
SELECT count(*)
FROM   wsh_trip_stops
WHERE  trip_id = p_trip_id;

CURSOR trip_info IS
SELECT vehicle_item_id,
       ship_method_code,
       mode_of_transport
FROM   wsh_trips
WHERE  trip_id = p_trip_id;

CURSOR deliveries_exist IS
SELECT dl.delivery_id
FROM   wsh_trips t,
       wsh_trip_stops st,
       wsh_delivery_legs dg,
       wsh_new_deliveries dl
WHERE  t.trip_id = p_trip_id AND
       st.trip_id = t.trip_id AND
       dg.pick_up_stop_id = st.stop_id AND
       dl.delivery_id = dg.delivery_id;

CURSOR stops_info IS
SELECT stop_id,
	  departure_fill_percent,
       departure_gross_weight,
       departure_volume
FROM   wsh_trip_stops
WHERE  trip_id = p_trip_id;

CURSOR vehicle_info IS
SELECT msi.minimum_fill_percent,
       msi.maximum_load_weight,
       msi.internal_volume
FROM   wsh_trips t,
       mtl_system_items msi
WHERE  t.trip_id = p_trip_id AND
       t.vehicle_item_id = msi.inventory_item_id AND
       t.vehicle_organization_id = msi.organization_id;

l_numstops BINARY_INTEGER;
l_del_id   NUMBER := NULL; --Bug 9308056 Changed data type to number from binary integer.
l_vehicle  NUMBER;
l_min_fill NUMBER;
l_max_wt   NUMBER;
l_max_vol  NUMBER;
l_ship_method VARCHAR2(30);
l_mode     wsh_trips.mode_of_transport%TYPE;

--
l_debug_on BOOLEAN;
--
l_module_name CONSTANT VARCHAR2(100) := 'wsh.plsql.' || G_PKG_NAME || '.' || 'CHECK_PLAN';
--
BEGIN

   --
   -- Debug Statements
   --
   --
   l_debug_on := WSH_DEBUG_INTERFACE.g_debug;
   --
   IF l_debug_on IS NULL
   THEN
       l_debug_on := WSH_DEBUG_SV.is_debug_enabled;
   END IF;
   --
   IF l_debug_on THEN
       WSH_DEBUG_SV.push(l_module_name);
       --
       WSH_DEBUG_SV.log(l_module_name,'P_TRIP_ID',P_TRIP_ID);
   END IF;
   --
   OPEN stops_exist;
   FETCH stops_exist INTO l_numstops;
   CLOSE stops_exist;

   IF ( nvl(l_numstops,0) < 2) THEN
      FND_MESSAGE.SET_NAME('WSH','WSH_TRIP_NO_STOPS');
	 --
	 -- Debug Statements
	 --
	 IF l_debug_on THEN
	     WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit WSH_TRIPS_PVT.GET_NAME',WSH_DEBUG_SV.C_PROC_LEVEL);
	 END IF;
	 --
	 FND_MESSAGE.SET_TOKEN('TRIP_NAME',wsh_trips_pvt.get_name(p_trip_id));
      x_return_status := WSH_UTIL_CORE.G_RET_STS_ERROR;
      WSH_UTIL_CORE.ADD_MESSAGE(x_return_status);
      --
      -- Debug Statements
      --
      IF l_debug_on THEN
          WSH_DEBUG_SV.pop(l_module_name);
      END IF;
      --
      RETURN;
   END IF;

   OPEN  trip_info;
   FETCH trip_info INTO l_vehicle, l_ship_method, l_mode;

   IF (trip_info%NOTFOUND) THEN
      CLOSE trip_info;
      FND_MESSAGE.SET_NAME('WSH','WSH_TRIP_NOT_FOUND');
      x_return_status := WSH_UTIL_CORE.G_RET_STS_ERROR;
      WSH_UTIL_CORE.ADD_MESSAGE(x_return_status);
      --
      -- Debug Statements
      --
      IF l_debug_on THEN
          WSH_DEBUG_SV.pop(l_module_name);
      END IF;
      --
      RETURN;
   END IF;

   CLOSE trip_info;

   --changes in 'firm' behavior - only ship method is reqd.
   --if tp is installed and mode happens to be TL, vehicle is required
   IF (l_ship_method IS NULL) THEN
      FND_MESSAGE.SET_NAME('WSH','WSH_TRIP_VEHICLE_SH_M_REQ');
      FND_MESSAGE.SET_TOKEN('TRIP_NAME',wsh_trips_pvt.get_name(p_trip_id));
      x_return_status := WSH_UTIL_CORE.G_RET_STS_ERROR;
      WSH_UTIL_CORE.ADD_MESSAGE(x_return_status);
      --
      -- Debug Statements
      --
      IF l_debug_on THEN
          WSH_DEBUG_SV.pop(l_module_name);
      END IF;
      --
      RETURN;
   END IF;

   IF l_mode='TRUCK' and l_vehicle is NULL AND WSH_UTIL_CORE.TP_IS_INSTALLED='Y' THEN
      FND_MESSAGE.SET_NAME('WSH','WSH_TRIP_MODE_TR_REQ_VEH');
      IF l_debug_on THEN
	 WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit WSH_TRIPS_PVT.GET_NAME',WSH_DEBUG_SV.C_PROC_LEVEL);
      END IF;
      FND_MESSAGE.SET_TOKEN('TRIP_NAME',wsh_trips_pvt.get_name(p_trip_id));
      x_return_status := WSH_UTIL_CORE.G_RET_STS_ERROR;
      WSH_UTIL_CORE.ADD_MESSAGE(x_return_status);
      --
      -- Debug Statements
      --
      IF l_debug_on THEN
          WSH_DEBUG_SV.pop(l_module_name);
      END IF;
      --
      RETURN;
   END IF;

   x_return_status := WSH_UTIL_CORE.G_RET_STS_SUCCESS;

   OPEN  deliveries_exist;
   FETCH deliveries_exist INTO l_del_id;
   CLOSE deliveries_exist;

   IF (l_del_id IS NULL) THEN
      FND_MESSAGE.SET_NAME('WSH','WSH_TRIP_NO_DELIVERIES');
	 --
	 -- Debug Statements
	 --
	 IF l_debug_on THEN
	     WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit WSH_TRIPS_PVT.GET_NAME',WSH_DEBUG_SV.C_PROC_LEVEL);
	 END IF;
	 --
	 FND_MESSAGE.SET_TOKEN('TRIP_NAME',wsh_trips_pvt.get_name(p_trip_id));
      x_return_status := WSH_UTIL_CORE.G_RET_STS_WARNING;
      WSH_UTIL_CORE.ADD_MESSAGE(x_return_status);
   END IF;

   IF (l_vehicle IS NOT NULL) THEN
     OPEN  vehicle_info;
     FETCH vehicle_info INTO l_min_fill, l_max_wt, l_max_vol;
     CLOSE vehicle_info;

     FOR st IN stops_info LOOP
       IF ((st.departure_fill_percent IS NOT NULL) AND ( l_min_fill IS NOT NULL) AND (st.departure_fill_percent < l_min_fill)) THEN
          FND_MESSAGE.SET_NAME('WSH','WSH_STOP_FILL_PC_MIN');
          --
          -- Debug Statements
          --
          IF l_debug_on THEN
              WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit WSH_TRIPS_PVT.GET_NAME',WSH_DEBUG_SV.C_PROC_LEVEL);
          END IF;
          --
          -- Bug 3697947
          FND_MESSAGE.SET_TOKEN('STOP_NAME',wsh_trip_stops_pvt.get_name(st.stop_id,p_caller));
          x_return_status := WSH_UTIL_CORE.G_RET_STS_WARNING;
          WSH_UTIL_CORE.ADD_MESSAGE(x_return_status);
       ELSIF ((st.departure_fill_percent IS NOT NULL) AND (st.departure_fill_percent > 100)) THEN
          FND_MESSAGE.SET_NAME('WSH','WSH_STOP_FILL_PC_MAX');
          --
          -- Debug Statements
          --
          IF l_debug_on THEN
              WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit WSH_TRIPS_PVT.GET_NAME',WSH_DEBUG_SV.C_PROC_LEVEL);
          END IF;
          --
          -- Bug 3697947
          FND_MESSAGE.SET_TOKEN('STOP_NAME',wsh_trip_stops_pvt.get_name(st.stop_id,p_caller));
          x_return_status := WSH_UTIL_CORE.G_RET_STS_WARNING;
          WSH_UTIL_CORE.ADD_MESSAGE(x_return_status);
       END IF;
       IF ((st.departure_gross_weight IS NOT NULL) AND ( l_max_wt IS NOT NULL) AND (st.departure_gross_weight > l_max_wt)) OR
          ((st.departure_fill_percent IS NOT NULL) AND ( l_max_vol IS NOT NULL) AND (st.departure_volume > l_max_vol)) THEN
          FND_MESSAGE.SET_NAME('WSH','WSH_STOP_MAX_WT_VOL_EXCEEDED');
          --
          -- Debug Statements
          --
          IF l_debug_on THEN
              WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit WSH_TRIPS_PVT.GET_NAME',WSH_DEBUG_SV.C_PROC_LEVEL);
          END IF;
          --
          -- Bug 3697947
          FND_MESSAGE.SET_TOKEN('STOP_NAME', wsh_trip_stops_pvt.get_name(st.stop_id, p_caller));
          x_return_status := WSH_UTIL_CORE.G_RET_STS_WARNING;
          WSH_UTIL_CORE.ADD_MESSAGE(x_return_status);
       END IF;

     END LOOP;

   END IF;

--
-- Debug Statements
--
IF l_debug_on THEN
    WSH_DEBUG_SV.pop(l_module_name);
END IF;
--
   EXCEPTION
      WHEN others THEN
	    wsh_util_core.default_handler('WSH_TRIP_VALIDATIONS.CHECK_PLAN');
	    x_return_status := WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR;
      IF l_debug_on THEN
        WSH_DEBUG_SV.logmsg(l_module_name,'Unexpected error has occured. Oracle error message is '|| SQLERRM,WSH_DEBUG_SV.C_UNEXPEC_ERR_LEVEL);
        WSH_DEBUG_SV.pop(l_module_name,'EXCEPTION:OTHERS');
      END IF;

END Check_Plan;




-----------------------------------------------------------------------------
--
-- Procedure:     Check_Unplan
-- Parameters:    trip_id, x_return_status
-- Description:   Checks for Unplan action pre-requisites which are
--                - Trip status is not CLOSED
--                - Trip is planned
--
-----------------------------------------------------------------------------

PROCEDURE Check_Unplan ( p_trip_id 		IN  NUMBER,
		         x_return_status 	OUT NOCOPY  VARCHAR2) IS

CURSOR trip_info IS
SELECT status_code,
       planned_flag,
       NVL(shipments_type_flag,'O') shipments_type_flag  -- J-IB-NPARIKH
FROM   wsh_trips
WHERE  trip_id = p_trip_id;

l_status_code  VARCHAR2(2);
l_planned_flag VARCHAR2(1);

--
l_debug_on BOOLEAN;
--
l_module_name CONSTANT VARCHAR2(100) := 'wsh.plsql.' || G_PKG_NAME || '.' || 'CHECK_UNPLAN';
--
l_shipments_type_flag     VARCHAR2(30);
BEGIN

   --
   -- Debug Statements
   --
   --
   l_debug_on := WSH_DEBUG_INTERFACE.g_debug;
   --
   IF l_debug_on IS NULL
   THEN
       l_debug_on := WSH_DEBUG_SV.is_debug_enabled;
   END IF;
   --
   IF l_debug_on THEN
       WSH_DEBUG_SV.push(l_module_name);
       --
       WSH_DEBUG_SV.log(l_module_name,'P_TRIP_ID',P_TRIP_ID);
   END IF;
   --
   OPEN  trip_info;
   FETCH trip_info INTO l_status_code, l_planned_flag,l_shipments_type_flag;

   IF (trip_info%NOTFOUND) THEN
      CLOSE trip_info;
      FND_MESSAGE.SET_NAME('WSH','WSH_TRIP_NOT_FOUND');
      x_return_status := WSH_UTIL_CORE.G_RET_STS_ERROR;
      WSH_UTIL_CORE.ADD_MESSAGE(x_return_status);
      --
      -- Debug Statements
      --
      IF l_debug_on THEN
          WSH_DEBUG_SV.pop(l_module_name);
      END IF;
      --
      RETURN;
   END IF;

   CLOSE trip_info;

   x_return_status := WSH_UTIL_CORE.G_RET_STS_SUCCESS;

--
-- Debug Statements
--
IF l_debug_on THEN
    WSH_DEBUG_SV.pop(l_module_name);
END IF;
--
   EXCEPTION
      WHEN others THEN
	    wsh_util_core.default_handler('WSH_TRIP_VALIDATIONS.CHECK_UNPLAN');
	    x_return_status := WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR;

--
-- Debug Statements
--
IF l_debug_on THEN
    WSH_DEBUG_SV.logmsg(l_module_name,'Unexpected error has occured. Oracle error message is '|| SQLERRM,WSH_DEBUG_SV.C_UNEXPEC_ERR_LEVEL);
    WSH_DEBUG_SV.pop(l_module_name,'EXCEPTION:OTHERS');
END IF;
--
END Check_Unplan;

PROCEDURE Dropoff_Del_Intransit ( p_trip_id		IN  NUMBER,
				  p_stop_id 	        IN  NUMBER,
		                  x_return_status 	OUT NOCOPY  VARCHAR2,
--tkt
                                  p_caller        IN      VARCHAR2 DEFAULT 'WSH') IS

CURSOR prev_stop_info IS
SELECT 1 from dual
WHERE exists ( select 1
FROM  wsh_trip_stops ds,
      wsh_delivery_legs dg,
      wsh_new_deliveries dl
WHERE ds.trip_id = p_trip_id
AND   dg.drop_off_stop_id = p_stop_id
AND   dg.delivery_id = dl.delivery_id
AND   dl.status_code IN ('CO','OP','PA'));

l_stop_id NUMBER;

--
l_debug_on BOOLEAN;
--
l_module_name CONSTANT VARCHAR2(100) := 'wsh.plsql.' || G_PKG_NAME || '.' || 'DROPOFF_DEL_INTRANSIT';
--
BEGIN

      --
      -- Debug Statements
      --
      --
      l_debug_on := WSH_DEBUG_INTERFACE.g_debug;
      --
      IF l_debug_on IS NULL
      THEN
          l_debug_on := WSH_DEBUG_SV.is_debug_enabled;
      END IF;
      --
      IF l_debug_on THEN
          WSH_DEBUG_SV.push(l_module_name);
          --
          WSH_DEBUG_SV.log(l_module_name,'P_TRIP_ID',P_TRIP_ID);
          WSH_DEBUG_SV.log(l_module_name,'P_STOP_ID',P_STOP_ID);
      END IF;
      --
      x_return_status := WSH_UTIL_CORE.G_RET_STS_SUCCESS;

      OPEN prev_stop_info;
      FETCH prev_stop_info INTO l_stop_id;
      IF (prev_stop_info%FOUND) THEN
         FND_MESSAGE.SET_NAME('WSH','WSH_STOP_PREV_NOT_CLOSED');
         --
         -- Debug Statements
         --
         IF l_debug_on THEN
             WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit WSH_TRIP_STOPS_PVT.GET_NAME',WSH_DEBUG_SV.C_PROC_LEVEL);
         END IF;
         --
         FND_MESSAGE.SET_TOKEN('STOP_NAME', wsh_trip_stops_pvt.get_name(p_stop_id, p_caller));
         close prev_stop_info;
         x_return_status := WSH_UTIL_CORE.G_RET_STS_ERROR;
         WSH_UTIL_CORE.ADD_MESSAGE(x_return_status);
         --
         -- Debug Statements
         --
         IF l_debug_on THEN
             WSH_DEBUG_SV.pop(l_module_name);
         END IF;
         --
         RETURN;
      END IF;
      close prev_stop_info;

--
-- Debug Statements
--
IF l_debug_on THEN
    WSH_DEBUG_SV.pop(l_module_name);
END IF;
--
   EXCEPTION
      WHEN others THEN
	    wsh_util_core.default_handler('WSH_TRIP_VALIDATIONS.Dropoff_Del_Intransit');
	    x_return_status := WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR;
            IF prev_stop_info%ISOPEN THEN
              CLOSE prev_stop_info;
            END IF;

  --
  -- Debug Statements
  --
  IF l_debug_on THEN
      WSH_DEBUG_SV.logmsg(l_module_name,'Unexpected error has occured. Oracle error message is '|| SQLERRM,WSH_DEBUG_SV.C_UNEXPEC_ERR_LEVEL);
      WSH_DEBUG_SV.pop(l_module_name,'EXCEPTION:OTHERS');
  END IF;
  --
END Dropoff_Del_Intransit;

-- Private procedure called to check if previous stop is closed

PROCEDURE Check_Prev_Stop_Close ( p_trip_id		IN  NUMBER,
                                  p_stop_id             IN  NUMBER, --wr
                                  p_curr_stop_seq       IN  NUMBER,
                                  p_curr_stop_type      IN  VARCHAR2,
                                  x_linked_stop_id      OUT NOCOPY NUMBER, --wr
		                  x_return_status 	OUT NOCOPY  VARCHAR2) IS

--wr
-- Check for linked internal or physical stop
-- so that it can be subsequently validated and updated.
--   1. if the input stop is dummy, get its linked physical stop.
--         (If physical stop is Arrived, the dummy stop must be Arrived or Closed,
--          which will be caught earlier in the group API flow.)
--   2. if the input stop is physical, get the dummy stop only if it is open.
--   if there is no link, do not select any record.
CURSOR c_linked_stop(p_trip_id IN NUMBER,
                     p_stop_id IN NUMBER)  IS
SELECT physical_stop_id linked_stop_id,
       1 link_type
FROM wsh_trip_stops
WHERE  stop_id = p_stop_id
AND    physical_stop_id IS NOT NULL
UNION
SELECT stop_id linked_stop_id,
       2 link_type
FROM wsh_trip_stops
WHERE  trip_id = p_trip_id
AND    physical_stop_id = p_stop_id
AND    status_code = 'OP';


l_linked_stop_rec c_linked_stop%ROWTYPE;
l_primary_stop_id  NUMBER;
l_secondary_stop_id NUMBER;

-- Pack J IB: KVENKATE
-- Select shipments type flag , sequence number
--    ignore the linked internal stop.
CURSOR  prev_stop_info(p_stop_id NUMBER) IS
SELECT  stop_id,
        status_code,
        stop_sequence_number,
        nvl(shipments_type_flag, 'O') shipments_type_flag
FROM    wsh_trip_stops
WHERE   trip_id = p_trip_id AND
        stop_sequence_number < p_curr_stop_seq  AND
        NVL(physical_stop_id,-1) <> p_stop_id AND --wr
        status_code IN ('OP', 'AR')  --wr
ORDER BY stop_sequence_number desc;

l_stop_date DATE;
l_stop_id   NUMBER;
l_stop_status  VARCHAR2(2);
l_stop_seq_num NUMBER;
l_shipments_type_flag VARCHAR2(30);
l_num_warning NUMBER := 0;
--
l_debug_on BOOLEAN;
--
l_module_name CONSTANT VARCHAR2(100) := 'wsh.plsql.' || G_PKG_NAME || '.' || 'CHECK_PREV_STOP_CLOSE';
--
BEGIN

      --
      -- Debug Statements
      --
      --
      l_debug_on := WSH_DEBUG_INTERFACE.g_debug;
      --
      IF l_debug_on IS NULL
      THEN
          l_debug_on := WSH_DEBUG_SV.is_debug_enabled;
      END IF;
      --
      IF l_debug_on THEN
          WSH_DEBUG_SV.push(l_module_name);
          --
          WSH_DEBUG_SV.log(l_module_name,'P_TRIP_ID',P_TRIP_ID);
          -- Pack J IB: KVENKATE
          WSH_DEBUG_SV.log(l_module_name, 'p_curr_stop_seq', p_curr_stop_seq);
          WSH_DEBUG_SV.log(l_module_name, 'p_curr_stop_type', p_curr_stop_type);
      END IF;
      --
      x_return_status := WSH_UTIL_CORE.G_RET_STS_SUCCESS;

      --wr
      OPEN c_linked_stop(p_trip_id, p_stop_id);
      FETCH c_linked_stop into l_linked_stop_rec;
      IF c_linked_stop%FOUND THEN
        x_linked_stop_id := l_linked_stop_rec.linked_stop_id;
        IF l_linked_stop_rec.link_type = 1 THEN
          l_primary_stop_id   := l_linked_stop_rec.linked_stop_id;
          l_secondary_stop_id := p_stop_id;
        ELSE
          l_primary_stop_id   := p_stop_id;
          l_secondary_stop_id := l_linked_stop_rec.linked_stop_id;
        END IF;
      ELSE
        l_primary_stop_id := p_stop_id;
        l_secondary_stop_id := NULL;
      END IF;
      CLOSE c_linked_stop;

      IF l_debug_on THEN
          WSH_DEBUG_SV.log(l_module_name,'l_linked_stop_rec.link_type',l_linked_stop_rec.link_type);
          WSH_DEBUG_SV.log(l_module_name,'l_linked_stop_rec.linked_stop_id',l_linked_stop_rec.linked_stop_id);
          WSH_DEBUG_SV.log(l_module_name,'l_primary_stop_id',l_primary_stop_id);
          WSH_DEBUG_SV.log(l_module_name,'l_primary_stop_id',l_secondary_stop_id);
          WSH_DEBUG_SV.log(l_module_name,'x_linked_stop_id',x_linked_stop_id);
      END IF;


      -- Pack J IB: KVENKATE
      -- Need to look at all previous stops to see if any is closed and is not inbound
      FOR prev_stop_rec IN prev_stop_info(l_primary_stop_id) LOOP
      --{

          IF l_debug_on THEN
            wsh_debug_sv.log(l_module_name, 'stop_seq_num', prev_stop_rec.stop_sequence_number);
            wsh_debug_sv.log(l_module_name, 'shipments_type_flag', prev_stop_rec.shipments_type_flag);
          END IF;


          IF (prev_stop_rec.status_code <> 'CL') THEN
          --{
             FND_MESSAGE.SET_NAME('WSH','WSH_STOP_PREV_NOT_CLOSED');
             --
             -- Debug Statements
             --
             IF l_debug_on THEN
                WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit WSH_TRIP_STOPS_PVT.GET_NAME',WSH_DEBUG_SV.C_PROC_LEVEL);
             END IF;
             --
             FND_MESSAGE.SET_TOKEN('STOP_NAME', wsh_trip_stops_pvt.get_name(prev_stop_rec.stop_id));
             -- Pack J IB: KVENKATE
             -- Set the return status based on checks of shipment_type_flag
             -- of current stop and the previous stop

             IF p_curr_stop_type IN ('O', 'M') AND prev_stop_rec.shipments_type_flag = 'I' THEN
                l_num_warning := l_num_warning + 1;
                WSH_UTIL_CORE.ADD_MESSAGE(WSH_UTIL_CORE.G_RET_STS_WARNING);
             ELSE
                WSH_UTIL_CORE.ADD_MESSAGE(WSH_UTIL_CORE.G_RET_STS_ERROR);
                RAISE FND_API.G_EXC_ERROR;
             END IF;

         --}
         END IF;
    --}
    END LOOP;

   -- Pack J IB: KVENKATE
   IF l_num_warning > 0 THEN
      x_return_status := WSH_UTIL_CORE.G_RET_STS_WARNING;
   END IF;

--
-- Debug Statements
--
IF l_debug_on THEN
    WSH_DEBUG_SV.pop(l_module_name);
END IF;
--
   EXCEPTION
      -- Pack J IB: KVENKATE
      WHEN FND_API.G_EXC_ERROR THEN
         x_return_status := WSH_UTIL_CORE.G_RET_STS_ERROR;
         IF l_debug_on THEN
            wsh_debug_sv.logmsg(l_module_name, 'FND_API.G_EXC_ERROR exception has occured.', wsh_debug_sv.c_excep_level);
            wsh_debug_sv.pop(l_module_name, 'EXCEPTION:FND_API.G_EXC_ERROR');
         END IF;
      --

      WHEN others THEN
            IF c_linked_stop%ISOPEN THEN
              CLOSE c_linked_stop;
            END IF;
	    wsh_util_core.default_handler('WSH_TRIP_VALIDATIONS.Check_Prev_Stop_Close');
	    x_return_status := WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR;
            IF prev_stop_info%ISOPEN THEN
              CLOSE prev_stop_info;
            END IF;

  --
  -- Debug Statements
  --
  IF l_debug_on THEN
      WSH_DEBUG_SV.logmsg(l_module_name,'Unexpected error has occured. Oracle error message is '|| SQLERRM,WSH_DEBUG_SV.C_UNEXPEC_ERR_LEVEL);
      WSH_DEBUG_SV.pop(l_module_name,'EXCEPTION:OTHERS');
  END IF;
  --
END Check_Prev_Stop_Close;


-----------------------------------------------------------------------------
--
-- Procedure:     Check_Trip_Close
-- Parameters:    trip_id, x_return_status
-- Description:   Checks for Trip Close action pre-requisites which are
-- 		  - Trip status is OPEN or IN-TRANSIT
--		  - If trip status is IN-TRANSIT then last stop status is ARRIVED or CLOSED [warning]
--
-----------------------------------------------------------------------------

PROCEDURE Check_Trip_Close ( p_trip_id 		IN  NUMBER,
		             x_return_status 	OUT NOCOPY  VARCHAR2) IS

CURSOR  open_stop(v_trip_id NUMBER) IS
SELECT 'OPEN STOP'
FROM   	wsh_trip_stops st
WHERE  	st.trip_id = v_trip_id
AND     st.status_code <> 'CL';


l_max_date  DATE;
l_stop_status  VARCHAR2(2);
l_trip_status  VARCHAR2(2);
l_dummy  VARCHAR2(20);

--
l_debug_on BOOLEAN;
--
l_module_name CONSTANT VARCHAR2(100) := 'wsh.plsql.' || G_PKG_NAME || '.' || 'CHECK_TRIP_CLOSE';
--
BEGIN

   --
   -- Debug Statements
   --
   --
   l_debug_on := WSH_DEBUG_INTERFACE.g_debug;
   --
   IF l_debug_on IS NULL
   THEN
       l_debug_on := WSH_DEBUG_SV.is_debug_enabled;
   END IF;
   --
   IF l_debug_on THEN
       WSH_DEBUG_SV.push(l_module_name);
       --
       WSH_DEBUG_SV.log(l_module_name,'P_TRIP_ID',P_TRIP_ID);
   END IF;
   --
   x_return_status := WSH_UTIL_CORE.G_RET_STS_SUCCESS;

   OPEN open_stop(p_trip_id);
   FETCH open_stop INTO l_dummy;

   IF (open_stop%FOUND) THEN
      x_return_status := WSH_UTIL_CORE.G_RET_STS_ERROR;
      WSH_UTIL_CORE.ADD_MESSAGE(x_return_status);
   END IF;

   CLOSE open_stop;

--
-- Debug Statements
--
IF l_debug_on THEN
    WSH_DEBUG_SV.pop(l_module_name);
END IF;
--
   EXCEPTION
      WHEN others THEN
	    wsh_util_core.default_handler('WSH_TRIP_VALIDATIONS.CHECK_TRIP_CLOSE');
	    x_return_status := WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR;
            IF open_stop%ISOPEN THEN
              CLOSE open_stop;
            END IF;

--
-- Debug Statements
--
IF l_debug_on THEN
    WSH_DEBUG_SV.logmsg(l_module_name,'Unexpected error has occured. Oracle error message is '|| SQLERRM,WSH_DEBUG_SV.C_UNEXPEC_ERR_LEVEL);
    WSH_DEBUG_SV.pop(l_module_name,'EXCEPTION:OTHERS');
END IF;
--
END Check_Trip_Close;


-----------------------------------------------------------------------------
--
-- Procedure:     Check_Trip_Delete
-- Parameters:    trip_id, x_return_status
-- Description:   Checks for Trip Delete action pre-requisites which are
-- 		  - Trip status is OPEN
--		  - Trip is not planned [warning]
--		  - No deliveries are assigned to trip [warning]
--		  - No freight costs are attached to trip [warning]
--
-----------------------------------------------------------------------------

PROCEDURE Check_Trip_Delete ( p_trip_id 	IN  NUMBER,
		              x_return_status 	OUT NOCOPY  VARCHAR2,
--tkt
                              p_caller        IN      VARCHAR2) IS

CURSOR trip_info IS
SELECT status_code,
       planned_flag
FROM   wsh_trips
WHERE  trip_id = p_trip_id;

CURSOR stops_info IS
SELECT stop_id
FROM   wsh_trip_stops
WHERE  trip_id = p_trip_id;

CURSOR freight_costs_exist IS
SELECT freight_cost_id
FROM   wsh_freight_costs
WHERE  trip_id = p_trip_id
FOR UPDATE NOWAIT;

l_status_code VARCHAR2(2);
l_planned_flag VARCHAR2(1);
l_return_status VARCHAR2(1);

l_freight_costs_flag VARCHAR2(1) := 'N';

--
l_debug_on BOOLEAN;
--
l_module_name CONSTANT VARCHAR2(100) := 'wsh.plsql.' || G_PKG_NAME || '.' || 'CHECK_TRIP_DELETE';
--
BEGIN

   --
   -- Debug Statements
   --
   --
   l_debug_on := WSH_DEBUG_INTERFACE.g_debug;
   --
   IF l_debug_on IS NULL
   THEN
       l_debug_on := WSH_DEBUG_SV.is_debug_enabled;
   END IF;
   --
   IF l_debug_on THEN
       WSH_DEBUG_SV.push(l_module_name);
       --
       WSH_DEBUG_SV.log(l_module_name,'P_TRIP_ID',P_TRIP_ID);
   END IF;
   --
   OPEN  trip_info;
   FETCH trip_info INTO l_status_code, l_planned_flag;

   IF (trip_info%NOTFOUND) THEN
      CLOSE trip_info;
      FND_MESSAGE.SET_NAME('WSH','WSH_TRIP_NOT_FOUND');
      x_return_status := WSH_UTIL_CORE.G_RET_STS_ERROR;
	 WSH_UTIL_CORE.ADD_MESSAGE(x_return_status);
      --
      -- Debug Statements
      --
      IF l_debug_on THEN
          WSH_DEBUG_SV.pop(l_module_name);
      END IF;
      --
      RETURN;
   END IF;

   CLOSE trip_info;

   IF (l_status_code <> 'OP') THEN
      FND_MESSAGE.SET_NAME('WSH','WSH_TRIP_INVALID_STATUS');
      FND_MESSAGE.SET_TOKEN('TRIP_NAME',wsh_trips_pvt.get_name(p_trip_id));
      x_return_status := WSH_UTIL_CORE.G_RET_STS_ERROR;
	 WSH_UTIL_CORE.ADD_MESSAGE(x_return_status);
      --
      -- Debug Statements
      --
      IF l_debug_on THEN
          WSH_DEBUG_SV.pop(l_module_name);
      END IF;
      --
      RETURN;
   END IF;

   x_return_status := WSH_UTIL_CORE.G_RET_STS_SUCCESS;

   IF (l_planned_flag = 'Y') THEN
      FND_MESSAGE.SET_NAME('WSH','WSH_TRIP_DELETE_PLAN_TRIP');
      --
      -- Debug Statements
      --
      IF l_debug_on THEN
          WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit WSH_TRIPS_PVT.GET_NAME',WSH_DEBUG_SV.C_PROC_LEVEL);
      END IF;
      --
      FND_MESSAGE.SET_TOKEN('TRIP_NAME', wsh_trips_pvt.get_name(p_trip_id));
      x_return_status := WSH_UTIL_CORE.G_RET_STS_WARNING;
	 WSH_UTIL_CORE.ADD_MESSAGE(x_return_status);
   ELSIF (l_planned_flag='F') THEN
      FND_MESSAGE.SET_NAME('WSH','WSH_DELETE_FIRM_TRIP');
      FND_MESSAGE.SET_TOKEN('TRIP_NAME',wsh_trips_pvt.get_name(p_trip_id));
      x_return_status := WSH_UTIL_CORE.G_RET_STS_ERROR;
      WSH_UTIL_CORE.ADD_MESSAGE(x_return_status);
      IF l_debug_on THEN
          WSH_DEBUG_SV.pop(l_module_name);
      END IF;
      RETURN;
   END IF;

   -- Checks if deliveries exist for any stop and locks the stops, legs for each delivery
   -- NOTE: p_trip_flag is set to 'Y' to prevent duplication of delivery warnings

   FOR st IN stops_info LOOP

	 check_stop_delete( st.stop_id, l_return_status, 'Y', p_caller);

	 IF (l_return_status <> WSH_UTIL_CORE.G_RET_STS_SUCCESS) THEN

	    IF (l_return_status <> WSH_UTIL_CORE.G_RET_STS_WARNING) THEN
		  --
		  -- Debug Statements
		  --
		  IF l_debug_on THEN
		      WSH_DEBUG_SV.pop(l_module_name);
		  END IF;
		  --
		  RETURN;
         ELSE
		  x_return_status := l_return_status;
         END IF;

	 END IF;

   END LOOP;

   -- Checks if freight costs exist for the trip and locks them

   FOR fc IN freight_costs_exist LOOP
	 l_freight_costs_flag := 'Y';
   END LOOP;

   IF (l_freight_costs_flag = 'Y') THEN
      FND_MESSAGE.SET_NAME('WSH','WSH_TRIP_DELETE_WITH_FC');
      --
      -- Debug Statements
      --
      IF l_debug_on THEN
          WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit WSH_TRIPS_PVT.GET_NAME',WSH_DEBUG_SV.C_PROC_LEVEL);
      END IF;
      --
      FND_MESSAGE.SET_TOKEN('TRIP_NAME', wsh_trips_pvt.get_name(p_trip_id));
      x_return_status := WSH_UTIL_CORE.G_RET_STS_WARNING;
	 WSH_UTIL_CORE.ADD_MESSAGE(x_return_status);
   END IF;

--
-- Debug Statements
--
IF l_debug_on THEN
    WSH_DEBUG_SV.pop(l_module_name);
END IF;
--
   EXCEPTION
      WHEN others THEN
	    wsh_util_core.default_handler('WSH_TRIP_VALIDATIONS.CHECK_TRIP_DELETE');
	    x_return_status := WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR;

--
-- Debug Statements
--
IF l_debug_on THEN
    WSH_DEBUG_SV.logmsg(l_module_name,'Unexpected error has occured. Oracle error message is '|| SQLERRM,WSH_DEBUG_SV.C_UNEXPEC_ERR_LEVEL);
    WSH_DEBUG_SV.pop(l_module_name,'EXCEPTION:OTHERS');
END IF;
--
END Check_Trip_Delete;


-----------------------------------------------------------------------------
--
-- Procedure:     Check_Change_Carrier
-- Parameters:    trip_id, x_return_status
-- Description:   Checks for Change Carrier action pre-requisites which are
-- 		  - Trip status is OPEN
--		  - If  GROUP_BY_CARRIER_FLAG is set for any delivery on trip then Ship Method for deliveries and delivery details on this trip is not specified
--
-----------------------------------------------------------------------------

PROCEDURE Check_Change_Carrier ( p_trip_id 	 IN  NUMBER,
		                 x_return_status OUT NOCOPY  VARCHAR2) IS

CURSOR trip_info IS
SELECT status_code,
       planned_flag
FROM   wsh_trips
WHERE  trip_id = p_trip_id;

CURSOR group_by_carrier_set IS
SELECT count(*)
FROM   wsh_trip_stops t,
       wsh_delivery_legs dg,
       wsh_new_deliveries dl,
       wsh_shipping_parameters wsp
WHERE  t.stop_id = p_trip_id AND
       dg.pick_up_stop_id = t.stop_id AND
       dl.delivery_id = dg.delivery_id AND
       dl.organization_id = wsp.organization_id AND
       dl.ship_method_code IS NOT NULL AND
       wsp.group_by_ship_method_flag = 'Y';

-- NEED TO INCLUDE RULE FOR FREIGHT COSTS

l_status_code VARCHAR2(2);
l_planned_flag VARCHAR2(1);
l_cnt NUMBER := NULL;

--
l_debug_on BOOLEAN;
--
l_module_name CONSTANT VARCHAR2(100) := 'wsh.plsql.' || G_PKG_NAME || '.' || 'CHECK_CHANGE_CARRIER';
--
BEGIN

   --
   -- Debug Statements
   --
   --
   l_debug_on := WSH_DEBUG_INTERFACE.g_debug;
   --
   IF l_debug_on IS NULL
   THEN
       l_debug_on := WSH_DEBUG_SV.is_debug_enabled;
   END IF;
   --
   IF l_debug_on THEN
       WSH_DEBUG_SV.push(l_module_name);
       --
       WSH_DEBUG_SV.log(l_module_name,'P_TRIP_ID',P_TRIP_ID);
   END IF;
   --
   OPEN	 trip_info;
   FETCH trip_info INTO l_status_code, l_planned_flag;

   IF (trip_info%NOTFOUND) THEN
      CLOSE trip_info;
      FND_MESSAGE.SET_NAME('WSH','WSH_TRIP_NOT_FOUND');
      x_return_status := WSH_UTIL_CORE.G_RET_STS_ERROR;
	 WSH_UTIL_CORE.ADD_MESSAGE(x_return_status);
      --
      -- Debug Statements
      --
      IF l_debug_on THEN
          WSH_DEBUG_SV.pop(l_module_name);
      END IF;
      --
      RETURN;
   END IF;

   CLOSE trip_info;

   OPEN  group_by_carrier_set;
   FETCH group_by_carrier_set INTO l_cnt;
   CLOSE group_by_carrier_set;

   x_return_status := WSH_UTIL_CORE.G_RET_STS_SUCCESS;

   IF (l_cnt IS NOT NULL) THEN
       FND_MESSAGE.SET_NAME('WSH','Group-by-carrier-set');
       x_return_status := WSH_UTIL_CORE.G_RET_STS_WARNING;
	  WSH_UTIL_CORE.ADD_MESSAGE(x_return_status);
   END IF;

--
-- Debug Statements
--
IF l_debug_on THEN
    WSH_DEBUG_SV.pop(l_module_name);
END IF;
--
   EXCEPTION
      WHEN others THEN
	    wsh_util_core.default_handler('WSH_TRIP_VALIDATIONS.CHECK_CHANGE_CARRIER');
	    x_return_status := WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR;

--
-- Debug Statements
--
IF l_debug_on THEN
    WSH_DEBUG_SV.logmsg(l_module_name,'Unexpected error has occured. Oracle error message is '|| SQLERRM,WSH_DEBUG_SV.C_UNEXPEC_ERR_LEVEL);
    WSH_DEBUG_SV.pop(l_module_name,'EXCEPTION:OTHERS');
END IF;
--
END Check_Change_Carrier;




-----------------------------------------------------------------------------
--
-- Procedure:     Check_Stop_Arrive
-- Parameters:    p_stop_id              input stop to validate
--                x_linked_stop_id       populated only if linked physical or dummy stop
--                                       is open.
--                x_return_status
-- Description:   Checks for Arrive action pre-requisites which are
--                (These prerequisites need to be updated)  --wr
--		  - Actual Arrival Date is specified ( if date is not specified
--		    then default the current date in Actual Arrival Date)
--		  - Not the first stop on a trip
--		  - Previous stop on this trip is CLOSED [warning]
-- NOTE: this warning allows the user to Close All Previous Stops, Ignore or Cancel.
--
-----------------------------------------------------------------------------

PROCEDURE Check_Stop_Arrive ( p_stop_id 	IN  NUMBER,
                              x_linked_stop_id  OUT NOCOPY  NUMBER,   --wr
		              x_return_status 	OUT NOCOPY  VARCHAR2) IS

-- Pack J IB: KVENKATE
-- Select shipment type flag, sequence number
CURSOR stop_info IS
SELECT stop_sequence_number,
       status_code,
       trip_id,
       nvl(shipments_type_flag, 'O') shipments_type_flag
FROM   wsh_trip_stops
WHERE  stop_id = p_stop_id;

l_stop_date       DATE;
l_status_code	  VARCHAR2(2);
l_first_date      DATE;
l_trip_id         NUMBER;

-- Pack J IB: KVENKATE
l_stop_seq_num    NUMBER;
l_shipments_type_flag VARCHAR2(30);
-- Pack J IB: KVENKATE

--
l_debug_on BOOLEAN;
--
l_module_name CONSTANT VARCHAR2(100) := 'wsh.plsql.' || G_PKG_NAME || '.' || 'CHECK_STOP_ARRIVE';
--
BEGIN

   --
   -- Debug Statements
   --
   --
   l_debug_on := WSH_DEBUG_INTERFACE.g_debug;
   --
   IF l_debug_on IS NULL
   THEN
       l_debug_on := WSH_DEBUG_SV.is_debug_enabled;
   END IF;
   --
   IF l_debug_on THEN
       WSH_DEBUG_SV.push(l_module_name);
       --
       WSH_DEBUG_SV.log(l_module_name,'P_STOP_ID',P_STOP_ID);
   END IF;
   --
   OPEN stop_info;
   -- PACK J: KVENKATE
     FETCH stop_info INTO l_stop_seq_num, l_status_code, l_trip_id, l_shipments_type_flag;

   IF (stop_info%NOTFOUND) THEN
      CLOSE stop_info;
      FND_MESSAGE.SET_NAME('WSH','WSH_STOP_NOT_FOUND');
      x_return_status := WSH_UTIL_CORE.G_RET_STS_ERROR;
	 WSH_UTIL_CORE.ADD_MESSAGE(x_return_status);
      --
      -- Debug Statements
      --
      IF l_debug_on THEN
          WSH_DEBUG_SV.pop(l_module_name);
      END IF;
      --
      RETURN;
   END IF;

   CLOSE stop_info;

   IF (l_status_code = 'CL') THEN
      FND_MESSAGE.SET_NAME('WSH','WSH_STOP_INVALID_STATUS');
      x_return_status := WSH_UTIL_CORE.G_RET_STS_ERROR;
	 WSH_UTIL_CORE.ADD_MESSAGE(x_return_status);
	 --
	 -- Debug Statements
	 --
	 IF l_debug_on THEN
	     WSH_DEBUG_SV.pop(l_module_name);
	 END IF;
	 --
	 RETURN;
   END IF;

  -- Pack J IB: KVENKATE
   Check_Prev_Stop_Close(
          p_trip_id => l_trip_id,
          p_stop_id => p_stop_id,  --wr
          p_curr_stop_seq => l_stop_seq_num,
          p_curr_stop_type => l_shipments_type_flag,
          x_linked_stop_id  => x_linked_stop_id,
          x_return_status => x_return_status);

--
-- Debug Statements
--
IF l_debug_on THEN
    WSH_DEBUG_SV.pop(l_module_name);
END IF;
--
   EXCEPTION
      WHEN others THEN
	    wsh_util_core.default_handler('WSH_TRIP_VALIDATIONS.CHECK_STOP_ARRIVE');
	    x_return_status := WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR;

--
-- Debug Statements
--
IF l_debug_on THEN
    WSH_DEBUG_SV.logmsg(l_module_name,'Unexpected error has occured. Oracle error message is '|| SQLERRM,WSH_DEBUG_SV.C_UNEXPEC_ERR_LEVEL);
    WSH_DEBUG_SV.pop(l_module_name,'EXCEPTION:OTHERS');
END IF;
--
END Check_Stop_Arrive;




-----------------------------------------------------------------------------
--
-- Procedure:     Check_Stop_Close
-- Parameters:    stop_id, x_return_status
-- Description:   Checks for Stop Close action pre-requisites which are
--                (These prerequisites need to be updated)  --wr
--                - Pick up deliveries are confirmed, in transit or closed. (bug 1550824)
--		  - Actual Arrival Date and Actual Departure Date are specified
--		    (if first or last trip stop on a trip then only one of the
--                  two dates need to be specified)
--		  - Previous stop on this trip is CLOSED (except for the first trip stop) [warning]
--
-----------------------------------------------------------------------------

PROCEDURE Check_Stop_Close ( p_stop_id 		IN  NUMBER,
		             x_return_status 	OUT NOCOPY  VARCHAR2,
--tkt
                             p_caller        IN      VARCHAR2) IS

CURSOR stop_info IS
SELECT planned_departure_date,
       status_code,
       trip_id
FROM   wsh_trip_stops
WHERE  stop_id = p_stop_id;

-- bug 1550824: find delivery not confirmed, in transit or closed.
CURSOR deliveries_still_open(p_stop_id NUMBER) IS
SELECT wnd.delivery_id
FROM   wsh_new_deliveries wnd,
       wsh_delivery_legs  wdl
WHERE  wdl.pick_up_stop_id = p_stop_id
AND    wnd.delivery_id     = wdl.delivery_id
AND    wnd.status_code IN ('OP', 'PA')
AND    rownum = 1;

l_stop_date       DATE;
l_status_code	  VARCHAR2(2);
l_trip_id         NUMBER;
l_delivery_id     NUMBER;  -- bug 1550824;

--
l_debug_on BOOLEAN;
--
l_module_name CONSTANT VARCHAR2(100) := 'wsh.plsql.' || G_PKG_NAME || '.' || 'CHECK_STOP_CLOSE';
--
BEGIN
   --
   -- Debug Statements
   --
   --
   l_debug_on := WSH_DEBUG_INTERFACE.g_debug;
   --
   IF l_debug_on IS NULL
   THEN
       l_debug_on := WSH_DEBUG_SV.is_debug_enabled;
   END IF;
   --
   IF l_debug_on THEN
       WSH_DEBUG_SV.push(l_module_name);
       --
       WSH_DEBUG_SV.log(l_module_name,'P_STOP_ID',P_STOP_ID);
   END IF;
   --
   x_return_status := WSH_UTIL_CORE.G_RET_STS_SUCCESS;

   OPEN stop_info;
   FETCH stop_info INTO l_stop_date, l_status_code, l_trip_id;

   IF (stop_info%NOTFOUND) THEN
      CLOSE stop_info;
      FND_MESSAGE.SET_NAME('WSH','WSH_STOP_NOT_FOUND');
      x_return_status := WSH_UTIL_CORE.G_RET_STS_ERROR;
	 WSH_UTIL_CORE.ADD_MESSAGE(x_return_status);
      --
      -- Debug Statements
      --
      IF l_debug_on THEN
          WSH_DEBUG_SV.pop(l_module_name);
      END IF;
      --
      RETURN;
   END IF;

   CLOSE stop_info;

   -- bug 1550824: check for deliveries not ready to pick up
   OPEN  deliveries_still_open(p_stop_id);
   FETCH deliveries_still_open INTO l_delivery_id;
   IF deliveries_still_open%NOTFOUND THEN
     l_delivery_id := NULL;
   END IF;
   CLOSE deliveries_still_open;

   IF l_delivery_id IS NOT NULL THEN
    FND_MESSAGE.SET_NAME('WSH', 'WSH_STOP_CLOSE_OP_PA_ERROR');
    --
    -- Debug Statements
    --
    IF l_debug_on THEN
        WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit WSH_TRIP_STOPS_PVT.GET_NAME',WSH_DEBUG_SV.C_PROC_LEVEL);
    END IF;
    --
    FND_MESSAGE.SET_TOKEN('STOP_NAME',wsh_trip_stops_pvt.get_name(p_stop_id, p_caller));
    x_return_status := WSH_UTIL_CORE.G_RET_STS_ERROR;
    WSH_UTIL_CORE.ADD_MESSAGE(x_return_status);
    --
    -- Debug Statements
    --
    IF l_debug_on THEN
        WSH_DEBUG_SV.pop(l_module_name);
    END IF;
    --
    RETURN;
   END IF;

   Dropoff_Del_Intransit(l_trip_id, p_stop_id, x_return_status, p_caller);

--
-- Debug Statements
--
IF l_debug_on THEN
    WSH_DEBUG_SV.pop(l_module_name);
END IF;
--
   EXCEPTION
      WHEN others THEN
	    wsh_util_core.default_handler('WSH_TRIP_VALIDATIONS.CHECK_STOP_CLOSE');
	    x_return_status := WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR;

--
-- Debug Statements
--
IF l_debug_on THEN
    WSH_DEBUG_SV.logmsg(l_module_name,'Unexpected error has occured. Oracle error message is '|| SQLERRM,WSH_DEBUG_SV.C_UNEXPEC_ERR_LEVEL);
    WSH_DEBUG_SV.pop(l_module_name,'EXCEPTION:OTHERS');
END IF;
--
END Check_Stop_Close;



-----------------------------------------------------------------------------
--
-- Procedure:     Check_Assign_Trip
-- Parameters:    stop_id, x_return_status
-- Description:   Checks for Assign Trip action pre-requisites which are
--		  - Trip status is not CLOSED
--		  - Trip is not planned
--		  - If trip has Vehicle information then vehicle is not over/under filled at this and subsequent stops [warning]
--               NOTE: The above three rules apply to both trip to be unassigned from and trip to be assigned to
--		  - Stop with the same location does not exist for the trip to be assigned to [warning]
--
-----------------------------------------------------------------------------

PROCEDURE Check_Assign_Trip ( p_stop_id 	IN  NUMBER,
			      p_trip_id		IN  NUMBER,
		              x_return_status 	OUT NOCOPY  VARCHAR2) IS
		              --
l_debug_on BOOLEAN;
		              --
		              l_module_name CONSTANT VARCHAR2(100) := 'wsh.plsql.' || G_PKG_NAME || '.' || 'CHECK_ASSIGN_TRIP';
		              --
BEGIN
   --
   -- Debug Statements
   --
   --
   l_debug_on := WSH_DEBUG_INTERFACE.g_debug;
   --
   IF l_debug_on IS NULL
   THEN
       l_debug_on := WSH_DEBUG_SV.is_debug_enabled;
   END IF;
   --
   IF l_debug_on THEN
       WSH_DEBUG_SV.push(l_module_name);
       --
       WSH_DEBUG_SV.log(l_module_name,'P_STOP_ID',P_STOP_ID);
       WSH_DEBUG_SV.log(l_module_name,'P_TRIP_ID',P_TRIP_ID);
   END IF;
   --
   x_return_status := WSH_UTIL_CORE.G_RET_STS_SUCCESS;
   --
   -- Debug Statements
   --
   IF l_debug_on THEN
       WSH_DEBUG_SV.pop(l_module_name);
   END IF;
   --
END Check_Assign_Trip;




-----------------------------------------------------------------------------
--
-- Procedure:     Check_Stop_Delete
-- Parameters:    stop_id, x_return_status
-- Description:   Checks for Delete Stop action pre-requisites which are
-- 		  - Stop status is OPEN
--                - Trip status is not CLOSED
--                - Trip is not planned
--                - No deliveries are assigned to this stop [warning]
--
-----------------------------------------------------------------------------

PROCEDURE Check_Stop_Delete ( p_stop_id 	  IN  NUMBER,
                              x_return_status  OUT NOCOPY  VARCHAR2,
		              p_trip_flag      IN  VARCHAR2 DEFAULT 'N',
--tkt
                              p_caller        IN      VARCHAR2) IS
CURSOR stop_info IS
SELECT t.status_code,
       t.planned_flag,
       st.status_code,
	t.trip_id
FROM   wsh_trips t,
       wsh_trip_stops st
WHERE  st.stop_id = p_stop_id AND
       st.trip_id = t.trip_id;

CURSOR pickup_deliveries IS
SELECT dg.delivery_id
FROM   wsh_trip_stops t,
       wsh_delivery_legs dg
WHERE  t.stop_id = p_stop_id AND
       dg.pick_up_stop_id = t.stop_id
FOR UPDATE NOWAIT;

CURSOR dropoff_deliveries IS
SELECT dg.delivery_id
FROM   wsh_trip_stops t,
       wsh_delivery_legs dg
WHERE  t.stop_id = p_stop_id AND
       dg.drop_off_stop_id = t.stop_id
FOR UPDATE NOWAIT;

CURSOR freight_costs_exist IS
SELECT freight_cost_id
FROM   wsh_freight_costs
WHERE  stop_id = p_stop_id
FOR UPDATE NOWAIT;

l_trip_status_code VARCHAR2(2);
l_planned_flag VARCHAR2(1);
l_stop_status_code VARCHAR2(2);
l_trip_id NUMBER;

l_del_flag VARCHAR2(1) := 'N';
l_freight_costs_flag VARCHAR2(1) := 'N';

--
l_debug_on BOOLEAN;
--
l_module_name CONSTANT VARCHAR2(100) := 'wsh.plsql.' || G_PKG_NAME || '.' || 'CHECK_STOP_DELETE';
--
BEGIN

   --
   -- Debug Statements
   --
   --
   l_debug_on := WSH_DEBUG_INTERFACE.g_debug;
   --
   IF l_debug_on IS NULL
   THEN
       l_debug_on := WSH_DEBUG_SV.is_debug_enabled;
   END IF;
   --
   IF l_debug_on THEN
       WSH_DEBUG_SV.push(l_module_name);
       --
       WSH_DEBUG_SV.log(l_module_name,'P_STOP_ID',P_STOP_ID);
       WSH_DEBUG_SV.log(l_module_name,'P_TRIP_FLAG',P_TRIP_FLAG);
   END IF;
   --
   OPEN  stop_info;
   FETCH stop_info INTO l_trip_status_code, l_planned_flag, l_stop_status_code, l_trip_id;

   IF (stop_info%NOTFOUND) THEN
      CLOSE stop_info;
      FND_MESSAGE.SET_NAME('WSH','WSH_STOP_NOT_FOUND');
      x_return_status := WSH_UTIL_CORE.G_RET_STS_ERROR;
	 WSH_UTIL_CORE.ADD_MESSAGE(x_return_status);
      --
      -- Debug Statements
      --
      IF l_debug_on THEN
          WSH_DEBUG_SV.pop(l_module_name);
      END IF;
      --
      RETURN;
   END IF;

   CLOSE stop_info;

   IF (l_stop_status_code <> 'OP') THEN
      FND_MESSAGE.SET_NAME('WSH','WSH_STOP_INVALID_STATUS');
      x_return_status := WSH_UTIL_CORE.G_RET_STS_ERROR;
	 WSH_UTIL_CORE.ADD_MESSAGE(x_return_status);
      --
      -- Debug Statements
      --
      IF l_debug_on THEN
          WSH_DEBUG_SV.pop(l_module_name);
      END IF;
      --
      RETURN;
   END IF;

   IF (l_trip_status_code = 'CL') THEN
      FND_MESSAGE.SET_NAME('WSH','WSH_TRIP_INVALID_STATUS');
      FND_MESSAGE.SET_TOKEN('TRIP_NAME',wsh_trips_pvt.get_name(l_trip_id));
      x_return_status := WSH_UTIL_CORE.G_RET_STS_ERROR;
	 WSH_UTIL_CORE.ADD_MESSAGE(x_return_status);
      --
      -- Debug Statements
      --
      IF l_debug_on THEN
          WSH_DEBUG_SV.pop(l_module_name);
      END IF;
      --
      RETURN;
   END IF;

   IF (l_planned_flag='Y') THEN
      FND_MESSAGE.SET_NAME('WSH','WSH_STOP_INVALID_TRIP_PLAN');
      --
      -- Debug Statements
      --
      IF l_debug_on THEN
          WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit WSH_TRIPS_PVT.GET_NAME',WSH_DEBUG_SV.C_PROC_LEVEL);
      END IF;
      --
      FND_MESSAGE.SET_TOKEN('TRIP_NAME', wsh_trips_pvt.get_name(l_trip_id));
      x_return_status := WSH_UTIL_CORE.G_RET_STS_ERROR;
	 WSH_UTIL_CORE.ADD_MESSAGE(x_return_status);
      --
      -- Debug Statements
      --
      IF l_debug_on THEN
          WSH_DEBUG_SV.pop(l_module_name);
      END IF;
      --
      RETURN;
   ELSIF (l_planned_flag ='F') THEN
      FND_MESSAGE.SET_NAME('WSH','WSH_STOP_INVALID_TRIP_FIRM');
      --
      -- Debug Statements
      --
      IF l_debug_on THEN
          WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit WSH_TRIPS_PVT.GET_NAME',WSH_DEBUG_SV.C_PROC_LEVEL);
      END IF;
      --
      FND_MESSAGE.SET_TOKEN('TRIP_NAME', wsh_trips_pvt.get_name(l_trip_id));
      x_return_status := WSH_UTIL_CORE.G_RET_STS_ERROR;
	 WSH_UTIL_CORE.ADD_MESSAGE(x_return_status);
      --
      -- Debug Statements
      --
      IF l_debug_on THEN
          WSH_DEBUG_SV.pop(l_module_name);
      END IF;
      --
      RETURN;
   END IF;

   x_return_status := WSH_UTIL_CORE.G_RET_STS_SUCCESS;

   FOR pd IN pickup_deliveries LOOP
      l_del_flag := 'Y';
   END LOOP;

   IF (l_del_flag <> 'Y') AND (p_trip_flag = 'N') THEN

      FOR dd IN dropoff_deliveries LOOP
         l_del_flag := 'Y';
      END LOOP;

   END IF;

   IF (l_del_flag = 'Y') THEN
      FND_MESSAGE.SET_NAME('WSH','WSH_STOP_DELETE_WITH_DELS');
      --
      -- Debug Statements
      --
      IF l_debug_on THEN
          WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit WSH_TRIP_STOPS_PVT.GET_NAME',WSH_DEBUG_SV.C_PROC_LEVEL);
      END IF;
      --
      FND_MESSAGE.SET_TOKEN('STOP_NAME', wsh_trip_stops_pvt.get_name(p_stop_id, p_caller));
      x_return_status := WSH_UTIL_CORE.G_RET_STS_WARNING;
	 WSH_UTIL_CORE.ADD_MESSAGE(x_return_status);
   END IF;

   -- Checks if freight costs exist for the stop and locks them

   FOR fc IN freight_costs_exist LOOP
	 l_freight_costs_flag := 'Y';
   END LOOP;

   IF (l_freight_costs_flag = 'Y') THEN
      FND_MESSAGE.SET_NAME('WSH','WSH_STOP_DELETE_WITH_FC');
      --
      -- Debug Statements
      --
      IF l_debug_on THEN
          WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit WSH_TRIP_STOPS_PVT.GET_NAME',WSH_DEBUG_SV.C_PROC_LEVEL);
      END IF;
      --
      FND_MESSAGE.SET_TOKEN('STOP_NAME', wsh_trip_stops_pvt.get_name(p_stop_id,p_caller));
      x_return_status := WSH_UTIL_CORE.G_RET_STS_WARNING;
	 WSH_UTIL_CORE.ADD_MESSAGE(x_return_status);
   END IF;

--
-- Debug Statements
--
IF l_debug_on THEN
    WSH_DEBUG_SV.pop(l_module_name);
END IF;
--
   EXCEPTION
      WHEN others THEN
	    wsh_util_core.default_handler('WSH_TRIP_VALIDATIONS.CHECK_STOP_DELETE');
	    x_return_status := WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR;

--
-- Debug Statements
--
IF l_debug_on THEN
    WSH_DEBUG_SV.logmsg(l_module_name,'Unexpected error has occured. Oracle error message is '|| SQLERRM,WSH_DEBUG_SV.C_UNEXPEC_ERR_LEVEL);
    WSH_DEBUG_SV.pop(l_module_name,'EXCEPTION:OTHERS');
END IF;
--
END Check_Stop_Delete;


-----------------------------------------------------------------------------
--
-- Procedure:     Get_Disabled_List
-- Parameters:    stop_id, x_return_status, p_trip_flag
-- Description:   Get the disabled columns/fields in a trip
--
-----------------------------------------------------------------------------

PROCEDURE Get_Disabled_List
  (p_trip_id        IN          NUMBER,
   p_list_type	    IN          VARCHAR2,
   x_return_status  OUT NOCOPY  VARCHAR2,
   x_disabled_list  OUT NOCOPY WSH_UTIL_CORE.COLUMN_TAB_TYPE,
   x_msg_count      OUT NOCOPY NUMBER,
   x_msg_data       OUT NOCOPY VARCHAR2,
   p_caller         IN         VARCHAR2 -- DEFAULT NULL, --3509004:public api changes
) IS

CURSOR get_trip_status(p_trip_id NUMBER)
IS
SELECT status_code
     , planned_flag
     , shipments_type_flag --3509004:public api changes
     , vehicle_organization_id -- Bug 3599626
     , lane_id
     , tp_plan_name -- OTM R12, glog proj
  FROM wsh_trips
 WHERE trip_id = p_trip_id;

--Cursor added for yms otm changes
CURSOR get_trip_load_status(cv_trip_id NUMBER)
IS
SELECT count(1)
  FROM wsh_delivery_details wdd
 WHERE equipment_id IS NOT NULL
   AND EXISTS( SELECT 1
                  FROM wsh_delivery_legs leg
                     , wsh_trip_stops stp
                     , wsh_delivery_assignments asg
                 WHERE asg.delivery_detail_id = wdd.delivery_detail_id
                   AND stp.stop_id = leg.pick_up_stop_id
                   AND stp.trip_id = cv_trip_id
                   AND leg.delivery_id = asg.delivery_id);

  i			 NUMBER := 0;
  l_tp_plan_name         WSH_TRIPS.TP_PLAN_NAME%TYPE; -- OTM R12, glog proj
  l_gc3_is_installed     VARCHAR(1); --OTM R12, glog proj
  l_status_code          VARCHAR2(10) := NULL;
  l_equipment_load_count NUMBER       := 0; --yms
  l_planned_flag         VARCHAR2(10) := NULL;
  l_vehicle_org_id       NUMBER; -- Bug 3599626
  l_msg_summary          VARCHAR2(2000) := NULL;
  l_msg_details          VARCHAR2(4000) := NULL;
  l_shipments_type_flag  VARCHAR(30) := NULL; --3509004:public api changes
  l_lane_id              NUMBER;
  e_all_disabled         EXCEPTION ; --3509004:public api changes

  WSH_DP_NO_ENTITY       EXCEPTION;
  WSH_INV_LIST_TYPE      EXCEPTION;
  --
  l_debug_on             BOOLEAN;
  --
  l_module_name CONSTANT VARCHAR2(100) := 'wsh.plsql.' || G_PKG_NAME || '.' || 'GET_DISABLED_LIST';
	--
BEGIN
   --
   -- Debug Statements
   --
   --
   l_debug_on := WSH_DEBUG_INTERFACE.g_debug;
   --
   IF l_debug_on IS NULL
   THEN
      l_debug_on := WSH_DEBUG_SV.is_debug_enabled;
   END IF;
   --
   IF l_debug_on THEN
      WSH_DEBUG_SV.push(l_module_name);
      --
      WSH_DEBUG_SV.log(l_module_name,'P_TRIP_ID',P_TRIP_ID);
      WSH_DEBUG_SV.log(l_module_name,'P_LIST_TYPE',P_LIST_TYPE);
   END IF;
   --

   x_return_status    := WSH_UTIL_CORE.G_RET_STS_SUCCESS;
   --OTM R12, glog proj, use Global Variable
   l_gc3_is_installed := WSH_UTIL_CORE.G_GC3_IS_INSTALLED;
   IF l_gc3_is_installed IS NULL THEN-- call function
      l_gc3_is_installed := WSH_UTIL_CORE.GC3_IS_INSTALLED;
   END IF;

   -- clear the disabled list first
   x_disabled_list.delete;

   -- open the trip
   OPEN get_trip_status(p_trip_id);
      FETCH get_trip_status
       INTO l_status_code,
            l_planned_flag,
            l_shipments_type_flag, --3509004:public api changes
            l_vehicle_org_id,
            l_lane_id,
            l_tp_plan_name; -- OTM R12, glog proj

      IF get_trip_status%NOTFOUND
      THEN
         CLOSE get_trip_status;
         RAISE WSH_DP_NO_ENTITY;
      END IF;
   CLOSE get_trip_status;

   --added for yms Start
   l_equipment_load_count := 0;

   OPEN get_trip_load_status(p_trip_id);
      FETCH get_trip_load_status
       INTO l_equipment_load_count;
   CLOSE get_trip_load_status;
   --added for yms end
   --DBMS_OUTPUT.PUT_LINE($$PLSQL_LINE);
   --DBMS_OUTPUT.PUT_LINE('l_equipment_load_count:'||l_equipment_load_count);
   IF (p_list_type <> 'FORM') THEN
      RAISE WSH_INV_LIST_TYPE;
   END IF;
   --DBMS_OUTPUT.PUT_LINE('l_status_code:'||l_status_code);
   IF ( l_status_code  = 'CL') THEN--{
      i:=i+1; x_disabled_list(i) := 'FULL';
      i:=i+1; x_disabled_list(i) := 'DESC_FLEX';
      i:=i+1; x_disabled_list(i) := 'OPERATOR';
   ELSIF ( l_status_code  = 'IT') THEN--} {
      i:=i+1; x_disabled_list(i) := 'FULL';
      i:=i+1; x_disabled_list(i) := 'DESC_FLEX';
      i:=i+1; x_disabled_list(i) := 'ROUTING_INSTRUCTIONS';
      i:=i+1; x_disabled_list(i) := 'OPERATOR';
      --Added for Bug 3309150
      IF NVL(p_caller,'''') LIKE 'FTE%' THEN --3509004:public api changes
         i:=i+1; x_disabled_list(i) := 'VEHICLE_ORGANIZATION_ID';
      ELSE
         i:=i+1; x_disabled_list(i) := 'VEHICLE_ORGANIZATION_CODE';
      END IF;
      -- BUG 3599626
      IF l_vehicle_org_id IS NOT NULL THEN
         IF  NVL(p_caller,'''') LIKE 'FTE%' THEN
           --DBMS_OUTPUT.PUT_LINE($$PLSQL_LINE);
            i:=i+1; x_disabled_list(i) := 'VEHICLE_ITEM_ID';
         ELSE
            i:=i+1; x_disabled_list(i) := 'VEHICLE_ITEM_NAME';
         END IF;
      END IF;
      --
   ELSIF (l_status_code = 'OP') THEN--} {
     --DBMS_OUTPUT.PUT_LINE($$PLSQL_LINE);
     --DBMS_OUTPUT.PUT_LINE('l_planned_flag:'||l_planned_flag);
      IF (l_planned_flag IN ('Y','F')) THEN--{
         i:=i+1; x_disabled_list(i) := 'FULL';
         i:=i+1; x_disabled_list(i) := 'DESC_FLEX';
         --bug 3257612 : load tender needs to update fields even if firm (any level)
         i:=i+1; x_disabled_list(i) := 'ROUTING_INSTRUCTIONS';
         i:=i+1; x_disabled_list(i) := 'LOAD_TENDER_STATUS';
         i:=i+1; x_disabled_list(i) := 'WF_NAME';
         i:=i+1; x_disabled_list(i) := 'WF_PROCESS_NAME';
         i:=i+1; x_disabled_list(i) := 'WF_ITEM_KEY';
         i:=i+1; x_disabled_list(i) := 'CARRIER_CONTACT_ID';
         i:=i+1; x_disabled_list(i) := 'SHIPPER_WAIT_TIME';
         i:=i+1; x_disabled_list(i) := 'WAIT_TIME_UOM';
         i:=i+1; x_disabled_list(i) := 'LOAD_TENDERED_TIME';
         i:=i+1; x_disabled_list(i) := 'CARRIER_RESPONSE';
         i:=i+1; x_disabled_list(i) := 'OPERATOR';
         -- Bug 3507047: Lane_id should be updatable on a firmed trip.
         i:=i+1; x_disabled_list(i) := 'LANE_ID';
         i:=i+1; x_disabled_list(i) := 'CARRIER_REFERENCE_NUMBER';
         i:=i+1; x_disabled_list(i) := 'CONSIGNEE_CARRIER_AC_NO';
         -- bug 4341253
         --i:=i+1; x_disabled_list(i) := 'VEHICLE_NUMBER'; -- YMS commented out,took care in below if
         --added for yms
         IF l_equipment_load_count = 0 THEN
            i:=i+1; x_disabled_list(i) := 'VEHICLE_ORGANIZATION_CODE';
            i:=i+1; x_disabled_list(i) := 'VEHICLE_NUM_PREFIX';
            i:=i+1; x_disabled_list(i) := 'VEHICLE_ITEM_ID';
            i:=i+1; x_disabled_list(i) := 'VEHICLE_ITEM_NAME';
            i:=i+1; x_disabled_list(i) := 'VEHICLE_NUMBER';
         END IF;


      END IF; --}-- end of l_planned_flag IN (Y/F)

      --OTM R12, glog proj
      IF l_debug_on THEN
         WSH_DEBUG_SV.logmsg(l_module_name,'l_tp_plan_name :'||l_tp_plan_name);
         WSH_DEBUG_SV.logmsg(l_module_name,'l_gc3_is_installed :'||l_gc3_is_installed);
         WSH_DEBUG_SV.logmsg(l_module_name,'l_planned_flag :'||l_planned_flag);
         WSH_DEBUG_SV.logmsg(l_module_name,'l_equipment_load_count :'||l_equipment_load_count);
      END IF;
      --yms added to disable the below fields on shipping trx trip tab
      -- if any of the associated delivery detail is loaded to trailer
      IF l_planned_flag NOT IN ('Y','F')
      THEN
         IF l_equipment_load_count > 0
         THEN
           --DBMS_OUTPUT.PUT_LINE($$PLSQL_LINE);
            i:=i+1; x_disabled_list(i) := 'VEHICLE_NUM_PREFIX';
            i:=i+1; x_disabled_list(i) := 'VEHICLE_ITEM_ID';
            i:=i+1; x_disabled_list(i) := 'VEHICLE_ITEM_NAME';
            i:=i+1; x_disabled_list(i) := 'VEHICLE_ORGANIZATION_CODE';
            i:=i+1; x_disabled_list(i) := 'VEHICLE_NUMBER';
         END IF;
      END IF;

      IF l_gc3_is_installed= 'Y' AND
         l_tp_plan_name IS NOT NULL
      THEN--{
         IF l_planned_flag = 'N' THEN
            i:=i+1; x_disabled_list(i) := 'FULL';
            i:=i+1; x_disabled_list(i) := 'DESC_FLEX';
            i:=i+1; x_disabled_list(i) := 'ROUTING_INSTRUCTIONS';
            i:=i+1; x_disabled_list(i) := 'OPERATOR';
            i:=i+1; x_disabled_list(i) := 'VEHICLE_NUMBER';
         END IF;
         IF l_debug_on THEN
            WSH_DEBUG_SV.logmsg(l_module_name, 'Caller :'||p_caller);
            WSH_DEBUG_SV.logmsg(l_module_name, 'Disabled List element 1:'||x_disabled_list(1));
            WSH_DEBUG_SV.logmsg(l_module_name, 'Before enabling others:');
         END IF;
         -- As planned_flag is not null field, x_disabled_list would
         -- have 1st element as FULL, so no need to check for <> FULL
         i:=i+1; x_disabled_list(i) := 'VEHICLE_NUM_PREFIX';
         i:=i+1; x_disabled_list(i) := 'VEHICLE_ITEM_NAME';
         i:=i+1; x_disabled_list(i) := 'VEHICLE_ORGANIZATION_CODE';
         i:=i+1; x_disabled_list(i) := 'SEAL_CODE';
         i:=i+1; x_disabled_list(i) := 'NAME';
      END IF;--} -- gc3 installed and tp_plan_name is NOT NULL
      --
   END IF; --} -- status_code = OP

   --
   --
   -- J-IB-NPARIKH-{
   --
   --
   -- Update on inbound trips are allowed only if caller
   -- starts with  one of the following:
   --     - FTE
   --     - WSH_IB
   --     - WSH_PUB
   --     - WSH_TP_RELEASE
   -- 3509004:public api changes

   IF WSH_YMS_INTEGRATION_PVT.is_dyms('TRIP',p_trip_id) ='N'-- DYMS Changes
   THEN -- DYMS Changes
      IF  NVL(l_shipments_type_flag,'O') = 'I' AND
      	  NVL(p_caller, '''')	NOT LIKE 'FTE%' AND
      	  NVL(p_caller, '''')	NOT LIKE 'WSH_PUB%' AND
      	  NVL(p_caller, '''')	NOT LIKE 'WSH_IB%' AND
      	  NVL(p_caller, '''')	NOT LIKE 'WSH_TP_RELEASE%'
      THEN
         RAISE e_all_disabled; --
      END IF;
   END IF;
   --
   --
   IF   l_status_code IN ('IT', 'CL')
      AND (
         NVL(l_shipments_type_flag,'O') = 'I'
         OR (
         NVL(l_shipments_type_flag,'O') = 'M'
         AND (   NVL(p_caller, '''')	LIKE 'FTE%'
         OR NVL(p_caller, '''')	LIKE 'WSH_PUB%'
         OR NVL(p_caller, '''')	LIKE 'WSH_IB%'
           )
          )
          )
   THEN
      --{
      --
      -- For inbound/mixed trips, following fields are updateable even if trip is closed.
      --   - carrier, mode of transport, service level, ship method,
      --     freight terms, carrier reference number,
      --     consignee carrier account number
      --                  --- only if NULL
      --   - vehicle number and vehicle number prefix.
      --
      -- For mixed trips, update is allowed only if caller starts with FTE/WSH_PUB/WSH_IB
      --
      IF x_disabled_list(1) = 'FULL'
      THEN
         i := x_disabled_list.count;
         --
         IF NVL(p_caller,'''') LIKE 'FTE%' THEN --3509004:public api changes
            i:=i+1; x_disabled_list(i) := '+CARRIER_ID';
            i:=i+1; x_disabled_list(i) := '+SERVICE_LEVEL';
            i:=i+1; x_disabled_list(i) := '+MODE_OF_TRANSPORT';
            i:=i+1; x_disabled_list(i) := '+SHIP_METHOD_CODE';
            i:=i+1; x_disabled_list(i) := '+LANE_ID';
            i:=i+1; x_disabled_list(i) := '+FREIGHT_TERMS_CODE';
         ELSE
            i:=i+1; x_disabled_list(i) := '+FREIGHT_CODE';
            i:=i+1; x_disabled_list(i) := '+SERVICE_LEVEL_NAME';
            i:=i+1; x_disabled_list(i) := '+MODE_OF_TRANSPORT_NAME';
            i:=i+1; x_disabled_list(i) := '+SHIP_METHOD_NAME';
            i:=i+1; x_disabled_list(i) := '+FREIGHT_TERMS_NAME';
            -- Added the LANE_ID here because when FTE calls our Grp
            -- API, we are converting the caller to WSH_PUB.
            i:=i+1; x_disabled_list(i) := '+LANE_ID';
         END IF;
         IF l_lane_id IS NULL THEN
            -- Per FTE disable CARRIER_REFERENCE_NUMBER if lane_id is
            -- not null (enable if null).
            i:=i+1; x_disabled_list(i) := '+CARRIER_REFERENCE_NUMBER';
         END IF;
         i:=i+1; x_disabled_list(i) := '+CONSIGNEE_CARRIER_AC_NO';
         i:=i+1; x_disabled_list(i) := 'VEHICLE_NUMBER';
         i:=i+1; x_disabled_list(i) := 'VEHICLE_NUM_PREFIX';
         i:=i+1; x_disabled_list(i) := 'OPERATOR';
      END IF;
      --}
   END IF;
   --
   -- J-IB-NPARIKH-}

--
-- Debug Statements
--
IF l_debug_on THEN
    WSH_DEBUG_SV.pop(l_module_name);
END IF;
--
EXCEPTION
  WHEN e_all_disabled THEN --3509004:public api changes
    -- OTM R12, glog proj
    IF get_trip_status%ISOPEN THEN
      CLOSE get_trip_status;
    END IF;
    x_return_status := WSH_UTIL_CORE.G_RET_STS_ERROR;
    FND_MESSAGE.SET_NAME('WSH','WSH_ALL_COLS_DISABLED');
    FND_MESSAGE.Set_Token('ENTITY_ID',p_trip_id);
    wsh_util_core.add_message(x_return_status,l_module_name);
    IF l_debug_on THEN
      -- Nothing is updateable
      WSH_DEBUG_SV.pop(l_module_name,'e_all_disabled');
    END IF;


  WHEN WSH_DP_NO_ENTITY THEN
    -- OTM R12, glog proj
    IF get_trip_status%ISOPEN THEN
      CLOSE get_trip_status;
    END IF;
    FND_MESSAGE.SET_NAME('WSH', 'WSH_DP_NO_ENTITY');
    WSH_UTIL_CORE.ADD_MESSAGE(FND_API.G_RET_STS_ERROR);
    x_return_status := FND_API.G_RET_STS_ERROR;
    WSH_UTIL_CORE.get_messages('Y', l_msg_summary, l_msg_details, x_msg_count);
    if x_msg_count > 1 then
      x_msg_data := l_msg_summary || l_msg_details;
    else
      x_msg_data := l_msg_summary;
    end if;

    -- invalid list type
    --
    -- Debug Statements
    --
    IF l_debug_on THEN
      WSH_DEBUG_SV.logmsg(l_module_name,'WSH_DP_NO_ENTITY exception has occured.',WSH_DEBUG_SV.C_EXCEP_LEVEL);
      WSH_DEBUG_SV.pop(l_module_name,'EXCEPTION:WSH_DP_NO_ENTITY');
    END IF;
    --
  WHEN WSH_INV_LIST_TYPE THEN
    -- OTM R12, glog proj
    IF get_trip_status%ISOPEN THEN
      CLOSE get_trip_status;
    END IF;
    FND_MESSAGE.SET_NAME('WSH', 'WSH_INV_LIST_TYPE');
    WSH_UTIL_CORE.ADD_MESSAGE(FND_API.G_RET_STS_ERROR);
    x_return_status := FND_API.G_RET_STS_ERROR;
    WSH_UTIL_CORE.get_messages('Y', l_msg_summary, l_msg_details, x_msg_count);
    if x_msg_count > 1 then
      x_msg_data := l_msg_summary || l_msg_details;
    else
      x_msg_data := l_msg_summary;
    end if;

    --
    -- Debug Statements
    --
    IF l_debug_on THEN
      WSH_DEBUG_SV.logmsg(l_module_name,'WSH_INV_LIST_TYPE exception has occured.',WSH_DEBUG_SV.C_EXCEP_LEVEL);
      WSH_DEBUG_SV.pop(l_module_name,'EXCEPTION:WSH_INV_LIST_TYPE');
    END IF;
    --
  WHEN OTHERS THEN
    IF get_trip_status%ISOPEN THEN
      CLOSE get_trip_status;
    END IF;

    FND_MESSAGE.Set_Name('WSH','WSH_UNEXPECTED_ERROR');
    x_return_status := WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR;


    --
    -- Debug Statements
    --
    IF l_debug_on THEN
      WSH_DEBUG_SV.logmsg(l_module_name,'Unexpected error has occured. Oracle error message is '|| SQLERRM,WSH_DEBUG_SV.C_UNEXPEC_ERR_LEVEL);
      WSH_DEBUG_SV.pop(l_module_name,'EXCEPTION:OTHERS');
    END IF;
    --
END  Get_Disabled_List  ;

--Harmonizing Project
/***************Validate_Planned_Trip***/
PROCEDURE validate_planned_trip
  (p_stop_id IN NUMBER,
   p_stop_sequence_number IN NUMBER,
   x_return_status OUT NOCOPY  VARCHAR2
  ) IS

CURSOR c_get_stop_seq IS
 SELECT stop_sequence_number,
        trip_id
   FROM wsh_trip_stops
  WHERE stop_id = p_stop_id;

-- kept it separte because this need not execute everytime
CURSOR c_get_trip_planned(v_trip_id IN NUMBER) IS
 SELECT planned_flag
   FROM wsh_trips
  WHERE trip_id = v_trip_id;

l_stop_sequence_number NUMBER;
l_trip_id NUMBER;
l_trip_planned VARCHAR2(1) := 'N' ;

--
l_debug_on BOOLEAN;
--
l_module_name CONSTANT VARCHAR2(100) := 'wsh.plsql.' || G_PKG_NAME || '.' || 'VALIDATE_PLANNED_TRIP';
--
BEGIN

  --
  -- Debug Statements
  --
  --
  l_debug_on := WSH_DEBUG_INTERFACE.g_debug;
  --
  IF l_debug_on IS NULL
  THEN
      l_debug_on := WSH_DEBUG_SV.is_debug_enabled;
  END IF;
  --
  IF l_debug_on THEN
      WSH_DEBUG_SV.push(l_module_name);
      --
      WSH_DEBUG_SV.log(l_module_name,'P_STOP_ID',P_STOP_ID);
      WSH_DEBUG_SV.log(l_module_name,'P_STOP_SEQUENCE_NUMBER',P_STOP_SEQUENCE_NUMBER);
  END IF;
  --
  IF (p_stop_id IS NOT NULL) THEN

    OPEN c_get_stop_seq;
    FETCH c_get_stop_seq
     INTO l_stop_sequence_number,
          l_trip_id;
    IF c_get_stop_seq%NOTFOUND THEN
      CLOSE c_get_stop_seq;
    ELSE
      CLOSE c_get_stop_seq;
    END IF;

    IF p_stop_sequence_number <> l_stop_sequence_number THEN
      OPEN c_get_trip_planned(l_trip_id);
      FETCH c_get_trip_planned
       INTO l_trip_planned;
      IF c_get_trip_planned%NOTFOUND THEN
        CLOSE c_get_trip_planned;
      ELSE
        CLOSE c_get_trip_planned;
      END IF;
-- new message
-- Stop Sequence Number cannot be updated for a planned trip.
      IF l_trip_planned ='Y' THEN
        FND_MESSAGE.Set_Name('WSH','WSH_PLANNED_TRIP');
        x_return_status := WSH_UTIL_CORE.G_RET_STS_ERROR;
        WSH_UTIL_CORE.ADD_MESSAGE(x_return_status);
        --
        -- Debug Statements
        --
        IF l_debug_on THEN
            WSH_DEBUG_SV.pop(l_module_name);
        END IF;
        --
        RETURN;
      ELSIF l_trip_planned = 'F' THEN
        FND_MESSAGE.Set_Name('WSH','WSH_FIRMED_TRIP');
        x_return_status := WSH_UTIL_CORE.G_RET_STS_ERROR;
        WSH_UTIL_CORE.ADD_MESSAGE(x_return_status);
        --
        -- Debug Statements
        --
        IF l_debug_on THEN
            WSH_DEBUG_SV.pop(l_module_name);
        END IF;
        --
        RETURN;
      END IF;


    END IF; -- for stop sequence number match
  END IF;

/*
  ELSE -- fields are not null
--invalid trip stop information
  FND_MESSAGE.Set_Name('WSH','WSH_STOP_NOT_FOUND');
  x_return_status := WSH_UTIL_CORE.G_RET_STS_ERROR;
  WSH_UTIL_CORE.ADD_MESSAGE(x_return_status);
  --
  -- Debug Statements
  --
  IF l_debug_on THEN
      WSH_DEBUG_SV.pop(l_module_name);
  END IF;
  --
  RETURN;

  END IF; -- fields are not null

*/
  x_return_status := WSH_UTIL_CORE.G_RET_STS_SUCCESS;
  --
  -- Debug Statements
  --
  IF l_debug_on THEN
      WSH_DEBUG_SV.pop(l_module_name);
  END IF;
  --
END validate_planned_trip;

--Harmonizing Project
PROCEDURE Is_Action_Enabled(
                p_trip_rec_tab          IN      trip_rec_tab_type,
                p_action                IN      VARCHAR2,
                p_caller                IN      VARCHAR2,
                x_return_status         OUT     NOCOPY VARCHAR2,
                x_valid_ids             OUT     NOCOPY wsh_util_core.id_tab_type,
                x_error_ids             OUT     NOCOPY wsh_util_core.id_tab_type,
                x_valid_index_tab       OUT     NOCOPY wsh_util_core.id_tab_type
          ) IS

-- Added wsp.otm_enabled column for OTM R12 - org specific
CURSOR  trip_to_del_cur(p_trip_id IN NUMBER) is
SELECT  wnd.delivery_id,
        wnd.organization_id,
        wnd.status_code,
        wnd.planned_flag,
/*J inbound logistics new column jckwok*/
        NVL(shipment_direction,'O') shipment_direction,
        wnd.delivery_type, --MDC
        NVL(wnd.ignore_for_planning, 'N') ignore_for_planning, -- OTM R12, glog proj
        NVL(wnd.tms_interface_flag,WSH_NEW_DELIVERIES_PVT.C_TMS_NOT_TO_BE_SENT) tms_interface_flag,  -- OTM R12, glog proj
        NVL(mcp.otm_enabled,wsp.otm_enabled) otm_enabled, -- OTM R12, glog proj-- LSP PROJECT : checking OTM enabled flag on client parameters.
        mcp.client_id -- LSP PROJECT
FROM    wsh_new_deliveries wnd,
        wsh_delivery_legs wdl,
        wsh_trip_stops wts1,
        wsh_trip_stops wts2,
        wsh_trips wt,
        wsh_shipping_parameters wsp,   --  OTM R12, glog proj
        mtl_client_parameters_v mcp       -- LSP PROJECT
WHERE   wnd.delivery_id = wdl.delivery_id
AND     wts1.stop_id = wdl.PICK_UP_STOP_ID
AND     wts2.stop_id = wdl.DROP_OFF_STOP_ID
AND     wts1.trip_id = wt.trip_id
AND     wts2.trip_id = wt.trip_id
AND     wt.trip_id   = p_trip_id
AND     wsp.organization_id = wnd.organization_id --  OTM R12, glog proj
AND     wnd.client_id =  mcp.client_id (+); -- LSP PROJECT


--Cursor addded for YMS project
CURSOR check_loaded_equipments(l_trip_id NUMBER)
IS
SELECT COUNT(DISTINCT(DECODE(wdd.equipment_id,NULL,0,1)))
  FROM wsh_trip_stops wts
     , wsh_delivery_legs wdl
     , wsh_new_deliveries wnd
     , wsh_delivery_details wdd
     , wsh_delivery_assignments wda
 WHERE wts.trip_id = l_trip_id
   AND wts.stop_id = wdl.pick_up_stop_id
   AND wts.stop_sequence_number = (SELECT MIN(stop_sequence_number)
                                     FROM wsh_trip_stops
                                    WHERE trip_id = l_trip_id
                                      AND status_code <> 'CL')
   AND wdl.delivery_id = wnd.delivery_id
   AND wda.delivery_id = wnd.delivery_id
   AND wda.delivery_detail_id = wdd.delivery_detail_id;

--End of cursor added for YMS


l_trip_actions_tab      TripActionsTabType;
l_valid_ids             wsh_util_core.id_tab_type;
l_error_ids             wsh_util_core.id_tab_type;
l_valid_index_tab       wsh_util_core.id_tab_type;
l_dlvy_rec_tab          WSH_DELIVERY_VALIDATIONS.dlvy_rec_tab_type;
l_move_id               NUMBER:= NULL;

l_pass_section_a        VARCHAR2(1):='Y';
l_tpw_temp              VARCHAR2(1);
l_status_code           VARCHAR2(1);
l_return_status         VARCHAR2(1);
error_in_init_actions   EXCEPTION;
e_set_messages          EXCEPTION;
e_yard_message          EXCEPTION; -- DYMS Changes
equipment_record_ineligible EXCEPTION; -- YMS changes
l_loaded_count          NUMBER := 1; -- YMS changes
l_debug_on BOOLEAN;
l_module_name CONSTANT VARCHAR2(100) := 'wsh.plsql.' || G_PKG_NAME || '.' || 'IS_ACTION_ENABLED';
--
l_caller                VARCHAR2(100);

l_loop_counter          NUMBER; --OTM R12, glog proj

BEGIN
 --
 l_debug_on := WSH_DEBUG_INTERFACE.g_debug;
 --
 IF l_debug_on IS NULL
 THEN
     l_debug_on := WSH_DEBUG_SV.is_debug_enabled;
 END IF;
 --
 IF l_debug_on THEN
    WSH_DEBUG_SV.push(l_module_name);
    --
    WSH_DEBUG_SV.log(l_module_name,'p_caller',p_caller);
    WSH_DEBUG_SV.log(l_module_name,'p_action',p_action);
 END IF;

 -- call initialize API and get the pl/sql table
 Init_Trip_Actions_Tbl(
	p_action => p_action,
	x_trip_actions_tab => l_trip_actions_tab,
	x_return_status => x_return_status);

 IF l_debug_on THEN
    WSH_DEBUG_SV.log(l_module_name,'Init_Detail_Actions_Tbl x_return_status',x_return_status);
 END IF;

 IF (x_return_status <> WSH_UTIL_CORE.G_RET_STS_SUCCESS ) THEN
    raise error_in_init_actions;
 END IF;


 FOR j IN p_trip_rec_tab.FIRST..p_trip_rec_tab.LAST LOOP
 BEGIN

     -- DYMS Start
     IF p_caller <> 'DYMS' AND
        p_action NOT IN ('TRIP-LOG-EXCEP','TRIP-CONFIRM','FIRM','UNPLAN')
     THEN
        IF WSH_YMS_INTEGRATION_PVT.is_dyms('TRIP',p_trip_rec_tab(j).trip_id) ='Y'
        THEN
           IF l_debug_on
           THEN
             wsh_debug_sv.logmsg(l_module_name, 'Error : DYMS TRIP : Action :'||p_action||'  Not allowed.');
           END IF;
           RAISE e_yard_message;
        END IF;
     END IF;
     -- DYMS End
     -- J-IB-NPARIKH-{
     --
     l_caller           := p_caller;
     --
     --
     IF l_debug_on THEN
        wsh_debug_sv.log(l_module_name, 'l_caller', l_caller);
     END IF;
        --
        --
        -- Actions on inbound trips are allowed only if caller
        -- starts with  one of the following:
        --     - FTE
        --     - WSH_IB
        --     - WSH_PUB
        --     - WSH_TP_RELEASE
        -- For any other callers, set l_caller to WSH_FSTRX
        -- Since for caller, WSH_FSTRX, all actions are disabled
        -- on inbound trips
        --
        --
        --
        IF  nvl(p_trip_rec_tab(j).shipments_type_flag,'O') = 'I'
        THEN
        --{
            IF l_caller LIKE 'FTE%'
            OR l_caller LIKE 'WSH_PUB%'
            OR l_caller LIKE 'WSH_IB%'
            OR l_caller LIKE 'DYMS%' -- DYMS
            OR l_caller LIKE 'WSH_TP_RELEASE%'
            THEN
                NULL;
            ELSE
                l_caller := 'WSH_FSTRX';
            END IF;
        --}
        END IF;
     --
     --
     IF l_debug_on THEN
        wsh_debug_sv.log(l_module_name, 'l_caller-modified', l_caller);
     END IF;
     -- J-IB-NPARIKH-}
     --
    -- section a
    -- YMS changes Start

     IF  p_action = 'TRIP-CONFIRM'
     THEN
        -- l_loaded_count 1 means that either all the delivery details
        -- are loaded to equipment or all are not loaded
        -- l_loaded_count 2 means some of the delivery details are loaded
        -- and some of them are not
        l_loaded_count := 1;

        OPEN check_loaded_equipments (p_trip_rec_tab(j).trip_id);
           FETCH check_loaded_equipments
            INTO l_loaded_count;
        CLOSE check_loaded_equipments;
        IF l_debug_on THEN
           wsh_debug_sv.log(l_module_name, 'l_loaded_count', l_loaded_count);
        END IF;

        IF l_loaded_count>1
        THEN
           RAISE equipment_record_ineligible;
        END IF;
     END IF;

    -- YMS changes  End

    IF ( l_trip_actions_tab.COUNT > 0 ) THEN
       l_loop_counter := l_trip_actions_tab.FIRST;
       LOOP -- OTM R12, loop modified per standard
          IF(NVL(l_trip_actions_tab(l_loop_counter).status_code,p_trip_rec_tab(j).status_code) = p_trip_rec_tab(j).status_code
             AND NVL(l_trip_actions_tab(l_loop_counter).planned_flag,NVL(p_trip_rec_tab(j).planned_flag,'N')) =
                      NVL(p_trip_rec_tab(j).planned_flag,'N')
             AND NVL(l_trip_actions_tab(l_loop_counter).load_tender_status,NVL(p_trip_rec_tab(j).load_tender_status,'OPEN')) =
                      NVL(p_trip_rec_tab(j).load_tender_status,'OPEN') -- 12 SELECT CARRIER
             AND NVL(l_trip_actions_tab(l_loop_counter).caller,l_caller) = l_caller   -- J-IB-NPARIKH
             AND l_trip_actions_tab(l_loop_counter).action_not_allowed = p_action
-- add check to compare shipments_type_flag jckwok
             AND NVL(l_trip_actions_tab(l_loop_counter).shipments_type_flag, NVL(p_trip_rec_tab(j).shipments_type_flag,'O')) = NVL(p_trip_rec_tab(j).shipments_type_flag,'O')
             --OTM R12, glog proj
             AND nvl(l_trip_actions_tab(l_loop_counter).ignore_for_planning, nvl(p_trip_rec_tab(j).ignore_for_planning, 'N')) = nvl(p_trip_rec_tab(j).ignore_for_planning, 'N')
         ) THEN

                IF l_trip_actions_tab(l_loop_counter).message_name IS NOT NULL THEN
                           IF l_debug_on THEN
                             wsh_debug_sv.log(l_module_name, 'Message Name is', l_trip_actions_tab(l_loop_counter).message_name);
                           END IF;
                           FND_MESSAGE.SET_NAME('WSH',l_trip_actions_tab(l_loop_counter).message_name);
                           wsh_util_core.add_message(wsh_util_core.g_ret_sts_error);
                END IF;
                RAISE e_set_messages;
          END IF;
       EXIT WHEN l_loop_counter >= l_trip_actions_tab.LAST;
       l_loop_counter := l_trip_actions_tab.NEXT(l_loop_counter);
       END LOOP;
    END IF;

    -- section b
    IF ( p_action = 'PICK-RELEASE')
    OR ( p_action = 'INCLUDE_PLAN')
    THEN
          FOR cur_rec IN trip_to_del_cur(p_trip_rec_tab(j).trip_id) LOOP
             l_dlvy_rec_tab(l_dlvy_rec_tab.count+1) := cur_rec;
          END LOOP;

          IF (l_dlvy_rec_tab.COUNT>0 AND p_action='INCLUDE_PLAN') OR (p_action='PICK-RELEASE') THEN
             WSH_DELIVERY_VALIDATIONS.Is_Action_Enabled(
                p_dlvy_rec_tab          => l_dlvy_rec_tab,
                p_action                => p_action,
                p_caller                => p_caller,
                x_return_status         => l_return_status,
                x_valid_ids             => l_valid_ids,
                x_error_ids             => l_error_ids,
                x_valid_index_tab       => l_valid_index_tab);

             IF l_debug_on THEN
               WSH_DEBUG_SV.log(l_module_name,'WSH_DELIVERY_VALIDATIONS.Is_Action_Enabled l_return_status',l_return_status);
             END IF;

             IF (l_return_status <> WSH_UTIL_CORE.G_RET_STS_SUCCESS)
             AND (l_return_status <> WSH_UTIL_CORE.G_RET_STS_WARNING)
             THEN
                 RAISE e_set_messages;
             --J-IB-NPARIKH--{
             ELSIF p_action        = 'INCLUDE_PLAN'
             AND   l_return_status = WSH_UTIL_CORE.G_RET_STS_WARNING
             THEN
                --
                -- If some of the deliveries cannot be included for planning,
                -- then trip cannot be included for planning.
                --
                RAISE e_set_messages;
                --J-IB-NPARIKH--}
             ELSE
             --{
                x_valid_ids(x_valid_ids.COUNT + 1) := p_trip_rec_tab(j).trip_id;
                x_valid_index_tab(j) := j;
             --}
             END IF;

          ELSE
             x_valid_ids(x_valid_ids.COUNT + 1) := p_trip_rec_tab(j).trip_id;
             x_valid_index_tab(j) := j;
          END IF;--l_dlvy_rec_tab.count>0
    ELSIF p_action = 'SELECT-CARRIER' THEN

          IF p_trip_rec_tab(j).lane_id IS NOT NULL THEN
             IF l_debug_on THEN
                  wsh_debug_sv.log(l_module_name, 'Trip has lane id : ', p_trip_rec_tab(j).lane_id);
             END IF;
             FND_MESSAGE.SET_NAME('WSH','WSH_FTE_SEL_TRIP_LANE');
             FND_MESSAGE.SET_TOKEN('TRIPID',p_trip_rec_tab(j).trip_id);
             wsh_util_core.add_message(wsh_util_core.g_ret_sts_error);
             RAISE e_set_messages;
          END IF;

          -- Perform continuous move check here
          l_move_id := WSH_FTE_INTEGRATION.GET_TRIP_MOVE(p_trip_rec_tab(j).trip_id);

          --IF l_move_id IS NOT NULL THEN
          IF l_move_id <> -1 THEN
             IF l_debug_on THEN
                  wsh_debug_sv.log(l_module_name, 'Trip has continuous move id id : ', l_move_id);
             END IF;
             FND_MESSAGE.SET_NAME('WSH','WSH_FTE_SEL_TRIP_MOVE');
             FND_MESSAGE.SET_TOKEN('TRIPID',p_trip_rec_tab(j).trip_id);
             wsh_util_core.add_message(wsh_util_core.g_ret_sts_error);
             RAISE e_set_messages;

          END IF;
          x_valid_ids(x_valid_ids.COUNT + 1) := p_trip_rec_tab(j).trip_id;
          x_valid_index_tab(j) := j;

    ELSE
          x_valid_ids(x_valid_ids.COUNT + 1) := p_trip_rec_tab(j).trip_id;
          x_valid_index_tab(j) := j;
    END IF;
 EXCEPTION
    -- DYMS Changes
    WHEN e_yard_message THEN
       x_error_ids(x_error_ids.COUNT + 1) := p_trip_rec_tab(j).trip_id;
       --IF p_caller = 'WSH_PUB' or p_caller like 'FTE%' THEN -- Commented for bug 22971801
          FND_MESSAGE.SET_NAME('WSH','WSH_INELIGIBLE_ACTION_FOR_YARD');
          wsh_util_core.add_message('E',l_module_name);
       --END IF;
    WHEN e_set_messages THEN
       x_error_ids(x_error_ids.COUNT + 1) := p_trip_rec_tab(j).trip_id;
       IF p_caller = 'WSH_PUB' or p_caller like 'FTE%' THEN
          FND_MESSAGE.SET_NAME('WSH','WSH_TRIP_ACTION_INELIGIBLE');
          FND_MESSAGE.Set_Token('ACTION',wsh_util_core.get_action_meaning('TRIP',p_action));
          FND_MESSAGE.Set_Token('TRIP_NAME',
                    wsh_trips_pvt.get_name(x_error_ids(x_error_ids.COUNT)));
          wsh_util_core.add_message('E',l_module_name);
       END IF;
-- YMS  start
    WHEN equipment_record_ineligible THEN
       x_error_ids(x_error_ids.COUNT + 1) := p_trip_rec_tab(j).trip_id;
       FND_MESSAGE.SET_NAME('WSH','WSH_EQP_TRIP_SHIPCONFIRM_ERROR');
       FND_MESSAGE.Set_Token('TRIP', wsh_trips_pvt.get_name(x_error_ids(x_error_ids.COUNT)));
       wsh_util_core.add_message('E',l_module_name);
-- YMS  End

 END;

 END LOOP; -- FOR j IN p_trip_rec_tab.FIRST

 IF (x_valid_ids.COUNT = 0 ) THEN
    x_return_status := WSH_UTIL_CORE.G_RET_STS_ERROR;
    --
    IF NOT (l_caller = 'WSH_PUB' OR l_caller LIKE 'FTE%') THEN
      FND_MESSAGE.SET_NAME('WSH','WSH_ACTION_ENABLED');
      wsh_util_core.add_message(x_return_status,l_module_name);
    END IF;
    --
 ELSIF (x_valid_ids.COUNT = p_trip_rec_tab.COUNT) THEN
    x_return_status := WSH_UTIL_CORE.G_RET_STS_SUCCESS;
 ELSIF (x_valid_ids.COUNT < p_trip_rec_tab.COUNT ) THEN
    x_return_status := WSH_UTIL_CORE.G_RET_STS_WARNING;
    --
    IF NOT (l_caller = 'WSH_PUB' OR l_caller LIKE 'FTE%') THEN
      FND_MESSAGE.SET_NAME('WSH','WSH_ACTION_ENABLED_WARN');
      wsh_util_core.add_message(x_return_status,l_module_name);
    END IF;
    --
 ElSE
    x_return_status := WSH_UTIL_CORE.G_RET_STS_ERROR;
    --
    IF NOT (l_caller = 'WSH_PUB' OR l_caller LIKE 'FTE%') THEN
      FND_MESSAGE.SET_NAME('WSH','WSH_ACTION_ENABLED');
      wsh_util_core.add_message(x_return_status,l_module_name);
    END IF;
    --
 END IF;

 IF l_debug_on THEN
    WSH_DEBUG_SV.pop(l_module_name);
 END IF;

EXCEPTION
  WHEN error_in_init_actions THEN
   IF l_debug_on THEN
      WSH_DEBUG_SV.logmsg(l_module_name,'error_in_init_actions exception has occured.',WSH_DEBUG_SV.C_EXCEP_LEVEL);
      WSH_DEBUG_SV.pop(l_module_name,'EXCEPTION:error_in_init_actions');
   END IF;

  WHEN OTHERS THEN
    wsh_util_core.default_handler('WSH_TRIP_VALIDATIONS.IS_ACTION_ENABLED');
   x_return_status := WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR;
   IF l_debug_on THEN
      WSH_DEBUG_SV.logmsg(l_module_name,'Unexpected error has occured. Oracle error message is '||
                          SQLERRM,WSH_DEBUG_SV.C_UNEXPEC_ERR_LEVEL);
      WSH_DEBUG_SV.pop(l_module_name,'EXCEPTION:OTHERS');
   END IF;
END Is_Action_Enabled;


PROCEDURE Validate_Arrive_after_trip(
  p_trip_id                   IN              NUMBER,
  p_arr_after_trip_id         IN OUT          NOCOPY NUMBER,
  p_arr_after_trip_name       IN              VARCHAR2,
  x_return_status            OUT              NOCOPY VARCHAR2) IS

CURSOR get_trip_id(cp_arr_after_trip_id NUMBER) IS
 SELECT 'X'
 FROM 	wsh_trips
 WHERE  trip_id = cp_arr_after_trip_id
 AND	status_code <> 'CL';

CURSOR get_trip_name(cp_arr_after_trip_name VARCHAR2) IS
 SELECT 'X',trip_id
 FROM 	wsh_trips
 WHERE  name = cp_arr_after_trip_name
 AND	status_code <> 'CL';

l_debug_on BOOLEAN;
l_module_name CONSTANT VARCHAR2(100) := 'wsh.plsql.' || G_PKG_NAME || '.' || 'VALIDATE_ARRIVE_AFTER_TRIP';
l_status 	VARCHAR2(1);
BEGIN
 --
 l_debug_on := WSH_DEBUG_INTERFACE.g_debug;
 --
 IF l_debug_on IS NULL
 THEN
     l_debug_on := WSH_DEBUG_SV.is_debug_enabled;
 END IF;
 --
 IF l_debug_on THEN
    WSH_DEBUG_SV.push(l_module_name);
    WSH_DEBUG_SV.log(l_module_name,'P_TRIP_ID',P_TRIP_ID);
    WSH_DEBUG_SV.log(l_module_name,'p_arr_after_trip_id',p_arr_after_trip_id);
    WSH_DEBUG_SV.log(l_module_name,'p_arr_after_trip_name',p_arr_after_trip_name);
 END IF;

 x_return_status := WSH_UTIL_CORE.G_RET_STS_SUCCESS;

 IF ((p_trip_id IS NULL OR p_trip_id = fnd_api.g_miss_num)
      OR ((p_arr_after_trip_id IS NULL OR p_arr_after_trip_id=fnd_api.g_miss_num)
           and (p_arr_after_trip_name IS NULL or p_arr_after_trip_name=fnd_api.g_miss_char)
          )
    ) THEN
   x_return_status := WSH_UTIL_CORE.G_RET_STS_SUCCESS;
   IF l_debug_on THEN
      WSH_DEBUG_SV.pop(l_module_name);
   END IF;
   RETURN;
 END IF;

 IF (p_trip_id = p_arr_after_trip_id ) THEN
   x_return_status := WSH_UTIL_CORE.G_RET_STS_ERROR;
 ELSE
   IF (p_arr_after_trip_id IS NOT NULL ) THEN
      OPEN get_trip_id(p_arr_after_trip_id);
      FETCH get_trip_id INTO l_status;
      CLOSE get_trip_id;
   ELSIF (p_arr_after_trip_name IS NOT NULL ) THEN
      OPEN get_trip_name(p_arr_after_trip_name);
      FETCH get_trip_name INTO l_status,p_arr_after_trip_id;
      CLOSE get_trip_name;
   ELSE
      l_status := FND_API.G_MISS_CHAR;
   END IF;

   IF (l_status IS NULL OR p_trip_id = p_arr_after_trip_id) THEN
      x_return_status := WSH_UTIL_CORE.G_RET_STS_ERROR;
   END IF;

 END IF;

 IF (x_return_status = WSH_UTIL_CORE.G_RET_STS_ERROR) THEN
   FND_MESSAGE.SET_NAME('WSH','WSH_OI_INVALID_ARR_AFTER_TRIP');
   WSH_UTIL_CORE.ADD_MESSAGE(x_return_status,l_module_name);
 END IF;

 IF l_debug_on THEN
    WSH_DEBUG_SV.pop(l_module_name);
 END IF;

EXCEPTION
  WHEN OTHERS THEN
    wsh_util_core.default_handler('WSH_TRIP_VALIDATIONS.VALIDATE_ARRIVE_AFTER_TRIP');
   x_return_status := WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR;
   IF l_debug_on THEN
      WSH_DEBUG_SV.logmsg(l_module_name,'Unexpected error has occured. Oracle error message is '||
                          SQLERRM,WSH_DEBUG_SV.C_UNEXPEC_ERR_LEVEL);
      WSH_DEBUG_SV.pop(l_module_name,'EXCEPTION:OTHERS');
   END IF;
END Validate_Arrive_after_trip;


PROCEDURE Validate_Consol_Allowed(
  p_trip_info                   IN      WSH_TRIPS_PVT.trip_rec_type,
  p_db_trip_info                IN      WSH_TRIPS_PVT.trip_rec_type,
  x_return_status               OUT     NOCOPY VARCHAR2) IS

 l_vehicle_item_id         wsh_trips.vehicle_item_id%type;
 l_vehicle_organization_id wsh_trips.vehicle_organization_id%type;
 l_ship_method_code        wsh_trips.ship_method_code%type;
 l_carrier_id              wsh_trips.carrier_id%type;
 l_service_level           wsh_trips.service_level%type;
 l_mode_of_transport       wsh_trips.mode_of_transport%type;
 l_lane_id                 wsh_trips.lane_id%type;
 l_c_truck                 CONSTANT VARCHAR2(10):='TRUCK';

 l_debug_on BOOLEAN;
 l_module_name CONSTANT VARCHAR2(100) := 'wsh.plsql.' || G_PKG_NAME || '.' || 'VALIDATE_CONSOL_ALLOWED';
 l_consolidation_allowed		VARCHAR2(100);
 l_entity_ids			WSH_UTIL_CORE.id_tab_type;
BEGIN
 --
 l_debug_on := WSH_DEBUG_INTERFACE.g_debug;
 --
 IF l_debug_on IS NULL
 THEN
     l_debug_on := WSH_DEBUG_SV.is_debug_enabled;
 END IF;
 --


 x_return_status := WSH_UTIL_CORE.G_RET_STS_SUCCESS;

 -- Bug fix: 3365750
 -- Do not give error if FTE is not installed.
 -- Proceed with code only if FTE is installed. Do nothing if NOT installed.
 IF (WSH_UTIL_CORE.FTE_IS_INSTALLED =  'Y') THEN
   --DBMS_OUTPUT.PUT_LINE($$PLSQL_LINE);
     l_consolidation_allowed   :=p_db_trip_info.consolidation_allowed;
     l_vehicle_item_id         :=p_db_trip_info.vehicle_item_id;
     l_vehicle_organization_id :=p_db_trip_info.vehicle_organization_id;
     l_ship_method_code        :=p_db_trip_info.ship_method_code;
     l_carrier_id              :=p_db_trip_info.carrier_id;
     l_service_level           :=p_db_trip_info.service_level;
     l_mode_of_transport       :=p_db_trip_info.mode_of_transport;
     l_lane_id                 :=p_db_trip_info.lane_id;

   IF l_debug_on THEN
      WSH_DEBUG_SV.push(l_module_name);
      WSH_DEBUG_SV.log(l_module_name,'P_TRIP_ID',p_trip_info.trip_id);
      WSH_DEBUG_SV.log(l_module_name,'p_consolidation_allowed',p_trip_info.consolidation_allowed);
      WSH_DEBUG_SV.log(l_module_name,'p_veh_item_id',p_trip_info.vehicle_item_id);
      WSH_DEBUG_SV.log(l_module_name,'p_veh_org_id',p_trip_info.vehicle_organization_id);
      WSH_DEBUG_SV.log(l_module_name,'p_ship_method_code',p_trip_info.ship_method_code);
      WSH_DEBUG_SV.log(l_module_name,'p_carrier_id',p_trip_info.carrier_id);
      WSH_DEBUG_SV.log(l_module_name,'p_service_level',p_trip_info.service_level);
      WSH_DEBUG_SV.log(l_module_name,'p_mode_of_transport',p_trip_info.mode_of_transport);
      WSH_DEBUG_SV.log(l_module_name,'p_lane_id',p_trip_info.lane_id);

      WSH_DEBUG_SV.log(l_module_name,'l_consolidation_allowed',l_consolidation_allowed);
      WSH_DEBUG_SV.log(l_module_name,'l_veh_item_id',l_vehicle_item_id);
      WSH_DEBUG_SV.log(l_module_name,'l_veh_org_id',l_vehicle_organization_id);
      WSH_DEBUG_SV.log(l_module_name,'l_ship_method_code',l_ship_method_code);
      WSH_DEBUG_SV.log(l_module_name,'l_carrier_id',l_carrier_id);
      WSH_DEBUG_SV.log(l_module_name,'l_service_level',l_service_level);
      WSH_DEBUG_SV.log(l_module_name,'l_mode_of_transport',l_mode_of_transport);
      WSH_DEBUG_SV.log(l_module_name,'l_lane_id',l_lane_id);
   END IF;


   --if lane_id, carrier_id, ship_method_code, service_level, mode_of_transport are changed
   --or if mode is truck and vehicle item or vehicle org is changed, then mark leg for reprice
   IF (
       (nvl(p_trip_info.lane_id,-99) <> FND_API.G_MISS_NUM AND (nvl(p_trip_info.lane_id,-99) <> nvl(l_lane_id,-99)))
       OR (nvl(p_trip_info.carrier_id,-99) <> FND_API.G_MISS_NUM AND (nvl(p_trip_info.carrier_id,-99) <> nvl(l_carrier_id,-99)))
       OR (nvl(p_trip_info.ship_method_code,'-99') <> FND_API.G_MISS_CHAR AND (nvl(p_trip_info.ship_method_code,'-99') <> nvl(l_ship_method_code,'-99')))
       OR (nvl(p_trip_info.service_level,'-99') <> FND_API.G_MISS_CHAR AND (nvl(p_trip_info.service_level,'-99') <> nvl(l_service_level,'-99')))
       OR (nvl(p_trip_info.mode_of_transport,'-99') <> FND_API.G_MISS_CHAR AND (nvl(p_trip_info.mode_of_transport,'-99') <> nvl(l_mode_of_transport,'-99')))
       OR (
            (p_trip_info.mode_of_transport=l_c_truck OR l_mode_of_transport=l_c_truck)
            AND (
                  (nvl(p_trip_info.vehicle_item_id,-99) <> FND_API.G_MISS_NUM AND (nvl(p_trip_info.vehicle_item_id,-99) <> nvl(l_vehicle_item_id,-99)))
                  OR (nvl(p_trip_info.vehicle_organization_id,-99) <> FND_API.G_MISS_NUM AND (nvl(p_trip_info.vehicle_organization_id,-99) <> nvl(l_vehicle_organization_id,-99)))
                )
          )
      ) THEN
      l_entity_ids(1):=p_trip_info.trip_id;
      WSH_DELIVERY_LEGS_ACTIONS.Mark_Reprice_Required(
		p_entity_type		=> 'TRIP',
 		p_entity_ids		=> l_entity_ids,
		p_consolidation_change	=> p_trip_info.consolidation_allowed,
		x_return_status		=> x_return_status);
    END IF;

 END IF;

 IF l_debug_on THEN
    WSH_DEBUG_SV.pop(l_module_name);
 END IF;

EXCEPTION
  WHEN OTHERS THEN
    wsh_util_core.default_handler('WSH_TRIP_VALIDATIONS.VALIDATE_CONSOL_ALLOWED');
   x_return_status := WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR;
   IF l_debug_on THEN
      WSH_DEBUG_SV.logmsg(l_module_name,'Unexpected error has occured. Oracle error message is '||
                          SQLERRM,WSH_DEBUG_SV.C_UNEXPEC_ERR_LEVEL);
      WSH_DEBUG_SV.pop(l_module_name,'EXCEPTION:OTHERS');
   END IF;
END Validate_Consol_Allowed;


/*
   Procedure populate_external_edf is called from
   eliminate_displayonly_fields to populate the external value
   for a given internal field
*/

PROCEDURE populate_external_edf(
  p_internal        IN   NUMBER
, p_external        IN   VARCHAR2
, x_internal        IN OUT  NOCOPY NUMBER
, x_external        IN OUT  NOCOPY VARCHAR2
)
IS
BEGIN

   IF p_internal <> FND_API.G_MISS_NUM OR p_internal IS NULL THEN
      x_internal := p_internal;
      IF p_internal IS NULL THEN
         x_external := NULL;
      ELSE
         x_external := p_external;
      END IF;
   ELSIF p_external <> FND_API.G_MISS_CHAR OR p_external IS NULL THEN
      x_external := p_external;
      IF x_external IS NULL THEN
         x_internal := NULL;
      ELSE
         x_internal := p_internal;
      END IF;
   END IF;

END populate_external_edf;



/*
   Procedure populate_external_edf is called from
   eliminate_displayonly_fields to populate the external value
   for a given internal field
*/

PROCEDURE populate_external_edf(
  p_internal        IN   VARCHAR2
, p_external        IN   VARCHAR2
, x_internal        IN OUT  NOCOPY VARCHAR2
, x_external        IN OUT  NOCOPY VARCHAR2
)
IS
BEGIN

   IF p_internal <> FND_API.G_MISS_CHAR OR p_internal IS NULL THEN
      x_internal := p_internal;
      IF p_internal IS NULL THEN
         x_external := NULL;
      ELSE
         x_external := p_external;
      END IF;
   ELSIF p_external <> FND_API.G_MISS_CHAR OR p_external IS NULL THEN
      x_external := p_external;
      IF x_external IS NULL THEN
         x_internal := NULL;
      ELSE
         x_internal := p_internal;
      END IF;
   END IF;

END populate_external_edf;



PROCEDURE eliminate_displayonly_fields (
  p_trip_rec   IN WSH_TRIPS_PVT.trip_rec_type
, p_in_rec	      IN  WSH_TRIPS_GRP.TripInRecType
, x_trip_rec   IN OUT NOCOPY WSH_TRIPS_PVT.trip_rec_type
)
IS
BEGIN

    /*
       Enable the x_delivery_detail_rec, with the columns that are not
       permanently  disabled.
    */
    IF p_trip_rec.NAME <> FND_API.G_MISS_CHAR
      OR p_trip_rec.NAME IS NULL THEN
      x_trip_rec.NAME := p_trip_rec.NAME;
    END IF;

    populate_external_edf(p_trip_rec.ship_method_code,
                          p_trip_rec.ship_method_name,
                          x_trip_rec.ship_method_code,
                          x_trip_rec.ship_method_name);

    IF p_trip_rec.CARRIER_ID <> FND_API.G_MISS_NUM
      OR p_trip_rec.CARRIER_ID IS NULL THEN
      x_trip_rec.CARRIER_ID := p_trip_rec.CARRIER_ID;
    END IF;

    IF p_trip_rec.ROUTE_ID <> FND_API.G_MISS_NUM
      OR p_trip_rec.ROUTE_ID IS NULL THEN
      x_trip_rec.ROUTE_ID := p_trip_rec.ROUTE_ID;
    END IF;
    IF p_trip_rec.FREIGHT_TERMS_CODE <> FND_API.G_MISS_CHAR
      OR p_trip_rec.FREIGHT_TERMS_CODE IS NULL THEN
      x_trip_rec.FREIGHT_TERMS_CODE := p_trip_rec.FREIGHT_TERMS_CODE;
    END IF;
    IF p_trip_rec.LOAD_TENDER_STATUS <> FND_API.G_MISS_CHAR
      OR p_trip_rec.LOAD_TENDER_STATUS IS NULL THEN
      x_trip_rec.LOAD_TENDER_STATUS := p_trip_rec.LOAD_TENDER_STATUS;
    END IF;
    IF p_trip_rec.LOAD_TENDER_NUMBER <> FND_API.G_MISS_NUM
      OR p_trip_rec.LOAD_TENDER_NUMBER IS NULL THEN
      x_trip_rec.LOAD_TENDER_NUMBER := p_trip_rec.LOAD_TENDER_NUMBER;
    END IF;
    IF p_trip_rec.VESSEL <> FND_API.G_MISS_CHAR
      OR p_trip_rec.VESSEL IS NULL THEN
      x_trip_rec.VESSEL := p_trip_rec.VESSEL;
    END IF;
    IF p_trip_rec.VOYAGE_NUMBER <> FND_API.G_MISS_CHAR
      OR p_trip_rec.VOYAGE_NUMBER IS NULL THEN
      x_trip_rec.VOYAGE_NUMBER := p_trip_rec.VOYAGE_NUMBER;
    END IF;
    IF p_trip_rec.PORT_OF_LOADING <> FND_API.G_MISS_CHAR
      OR p_trip_rec.PORT_OF_LOADING IS NULL THEN
      x_trip_rec.PORT_OF_LOADING:= p_trip_rec.PORT_OF_LOADING;
    END IF;
    IF p_trip_rec.PORT_OF_DISCHARGE <> FND_API.G_MISS_CHAR
      OR p_trip_rec.PORT_OF_DISCHARGE IS NULL THEN
      x_trip_rec.PORT_OF_DISCHARGE := p_trip_rec.PORT_OF_DISCHARGE;
    END IF;
    IF p_trip_rec.WF_NAME <> FND_API.G_MISS_CHAR
      OR p_trip_rec.WF_NAME IS NULL THEN
      x_trip_rec.WF_NAME := p_trip_rec.WF_NAME;
    END IF;
    IF p_trip_rec.WF_PROCESS_NAME <> FND_API.G_MISS_CHAR
      OR p_trip_rec.WF_PROCESS_NAME IS NULL THEN
      x_trip_rec.WF_PROCESS_NAME := p_trip_rec.WF_PROCESS_NAME;
    END IF;
    IF p_trip_rec.WF_ITEM_KEY <> FND_API.G_MISS_CHAR
      OR p_trip_rec.WF_ITEM_KEY IS NULL THEN
      x_trip_rec.WF_ITEM_KEY := p_trip_rec.WF_ITEM_KEY;
    END IF;
    IF p_trip_rec.CARRIER_CONTACT_ID <> FND_API.G_MISS_NUM
      OR p_trip_rec.CARRIER_CONTACT_ID IS NULL THEN
      x_trip_rec.CARRIER_CONTACT_ID := p_trip_rec.CARRIER_CONTACT_ID;
    END IF;
    IF p_trip_rec.SHIPPER_WAIT_TIME <> FND_API.G_MISS_NUM
      OR p_trip_rec.SHIPPER_WAIT_TIME IS NULL THEN
      x_trip_rec.SHIPPER_WAIT_TIME := p_trip_rec.SHIPPER_WAIT_TIME;
    END IF;
    IF p_trip_rec.WAIT_TIME_UOM <> FND_API.G_MISS_CHAR
      OR p_trip_rec.WAIT_TIME_UOM IS NULL THEN
      x_trip_rec.WAIT_TIME_UOM := p_trip_rec.WAIT_TIME_UOM;
    END IF;
    IF p_trip_rec.LOAD_TENDERED_TIME <> FND_API.G_MISS_DATE
      OR p_trip_rec.LOAD_TENDERED_TIME IS NULL THEN
      x_trip_rec.LOAD_TENDERED_TIME := p_trip_rec.LOAD_TENDERED_TIME;
    END IF;
    IF p_trip_rec.CARRIER_RESPONSE <> FND_API.G_MISS_CHAR
      OR p_trip_rec.CARRIER_RESPONSE IS NULL THEN
      x_trip_rec.CARRIER_RESPONSE := p_trip_rec.CARRIER_RESPONSE;
    END IF;

    IF p_trip_rec.ROUTE_LANE_ID <> FND_API.G_MISS_NUM
      OR p_trip_rec.ROUTE_LANE_ID IS NULL THEN
      x_trip_rec.ROUTE_LANE_ID := p_trip_rec.ROUTE_LANE_ID;
    END IF;
    IF p_trip_rec.LANE_ID <> FND_API.G_MISS_NUM
      OR p_trip_rec.LANE_ID IS NULL THEN
      x_trip_rec.LANE_ID := p_trip_rec.LANE_ID;
    END IF;
    IF p_trip_rec.SCHEDULE_ID <> FND_API.G_MISS_NUM
      OR p_trip_rec.SCHEDULE_ID IS NULL THEN
      x_trip_rec.SCHEDULE_ID := p_trip_rec.SCHEDULE_ID;
    END IF;
    IF p_trip_rec.BOOKING_NUMBER <> FND_API.G_MISS_CHAR
      OR p_trip_rec.BOOKING_NUMBER IS NULL THEN
      x_trip_rec.BOOKING_NUMBER := p_trip_rec.BOOKING_NUMBER;
    END IF;

    IF p_trip_rec.SERVICE_LEVEL <> FND_API.G_MISS_CHAR
      OR p_trip_rec.SERVICE_LEVEL IS NULL THEN
      x_trip_rec.SERVICE_LEVEL := p_trip_rec.SERVICE_LEVEL;
    END IF;
    IF p_trip_rec.MODE_OF_TRANSPORT <> FND_API.G_MISS_CHAR
      OR p_trip_rec.MODE_OF_TRANSPORT IS NULL THEN
      x_trip_rec.MODE_OF_TRANSPORT := p_trip_rec.MODE_OF_TRANSPORT;
    END IF;
    IF p_trip_rec.IGNORE_FOR_PLANNING <> FND_API.G_MISS_CHAR
      AND (p_in_rec.CALLER LIKE 'FTE%' OR p_in_rec.CALLER LIKE 'WSH_CONSOL%')
      AND p_in_rec.ACTION_CODE = 'CREATE' THEN
      -- bug 3694794: FTE needs to create trip with ignore = Y
      x_trip_rec.IGNORE_FOR_PLANNING := p_trip_rec.IGNORE_FOR_PLANNING;
    END IF;
    --DBMS_OUTPUT.PUT_LINE($$PLSQL_LINE);
    populate_external_edf(p_trip_rec.VEHICLE_ORGANIZATION_ID,
                          p_trip_rec.VEHICLE_ORGANIZATION_CODE,
                          x_trip_rec.VEHICLE_ORGANIZATION_ID,
                          x_trip_rec.VEHICLE_ORGANIZATION_CODE);

    populate_external_edf(p_trip_rec.VEHICLE_ITEM_ID,
                          p_trip_rec.VEHICLE_ITEM_DESC,
                          x_trip_rec.VEHICLE_ITEM_ID,
                          x_trip_rec.VEHICLE_ITEM_DESC);

    IF p_trip_rec.VEHICLE_NUM_PREFIX <> FND_API.G_MISS_CHAR
      OR p_trip_rec.VEHICLE_NUM_PREFIX IS NULL THEN
      x_trip_rec.VEHICLE_NUM_PREFIX := p_trip_rec.VEHICLE_NUM_PREFIX;
    END IF;
    IF p_trip_rec.VEHICLE_NUMBER <> FND_API.G_MISS_CHAR
      OR p_trip_rec.VEHICLE_NUMBER IS NULL THEN
      x_trip_rec.VEHICLE_NUMBER := p_trip_rec.VEHICLE_NUMBER;
    END IF;

    populate_external_edf(p_trip_rec.ARRIVE_AFTER_TRIP_ID,
                          p_trip_rec.ARRIVE_AFTER_TRIP_NAME,
                          x_trip_rec.ARRIVE_AFTER_TRIP_ID,
                          x_trip_rec.ARRIVE_AFTER_TRIP_NAME);

    IF p_trip_rec.ROUTING_INSTRUCTIONS <> FND_API.G_MISS_CHAR
      OR p_trip_rec.ROUTING_INSTRUCTIONS IS NULL THEN
      x_trip_rec.ROUTING_INSTRUCTIONS := p_trip_rec.ROUTING_INSTRUCTIONS;
    END IF;
    IF p_trip_rec.CONSOLIDATION_ALLOWED <> FND_API.G_MISS_CHAR
      OR p_trip_rec.CONSOLIDATION_ALLOWED IS NULL THEN
      x_trip_rec.CONSOLIDATION_ALLOWED := p_trip_rec.CONSOLIDATION_ALLOWED;
    END IF;
    IF p_trip_rec.OPERATOR <> FND_API.G_MISS_CHAR
      OR p_trip_rec.OPERATOR IS NULL THEN
      x_trip_rec.OPERATOR := p_trip_rec.OPERATOR;
    END IF;

    IF p_trip_rec.attribute1 <> FND_API.G_MISS_CHAR
      OR p_trip_rec.attribute1 IS NULL THEN
      x_trip_rec.attribute1 := p_trip_rec.attribute1;
    END IF;
    IF p_trip_rec.attribute2 <> FND_API.G_MISS_CHAR
      OR p_trip_rec.attribute2 IS NULL THEN
      x_trip_rec.attribute2 := p_trip_rec.attribute2;
    END IF;
    IF p_trip_rec.attribute3 <> FND_API.G_MISS_CHAR
      OR p_trip_rec.attribute3 IS NULL THEN
      x_trip_rec.attribute3 := p_trip_rec.attribute3;
    END IF;
    IF p_trip_rec.attribute4 <> FND_API.G_MISS_CHAR
      OR p_trip_rec.attribute4 IS NULL THEN
      x_trip_rec.attribute4 := p_trip_rec.attribute4;
    END IF;
    IF p_trip_rec.attribute5 <> FND_API.G_MISS_CHAR
      OR p_trip_rec.attribute5 IS NULL THEN
      x_trip_rec.attribute5 := p_trip_rec.attribute5;
    END IF;
    IF p_trip_rec.attribute6 <> FND_API.G_MISS_CHAR
      OR p_trip_rec.attribute6 IS NULL THEN
      x_trip_rec.attribute6 := p_trip_rec.attribute6;
    END IF;
    IF p_trip_rec.attribute7 <> FND_API.G_MISS_CHAR
      OR p_trip_rec.attribute7 IS NULL THEN
      x_trip_rec.attribute7 := p_trip_rec.attribute7;
    END IF;
    IF p_trip_rec.attribute8 <> FND_API.G_MISS_CHAR
      OR p_trip_rec.attribute8 IS NULL THEN
      x_trip_rec.attribute8 := p_trip_rec.attribute8;
    END IF;
    IF p_trip_rec.attribute9 <> FND_API.G_MISS_CHAR
      OR p_trip_rec.attribute9 IS NULL THEN
      x_trip_rec.attribute9 := p_trip_rec.attribute9;
    END IF;
    IF p_trip_rec.attribute10 <> FND_API.G_MISS_CHAR
      OR p_trip_rec.attribute10 IS NULL THEN
      x_trip_rec.attribute10 := p_trip_rec.attribute10;
    END IF;
    IF p_trip_rec.attribute11 <> FND_API.G_MISS_CHAR
      OR p_trip_rec.attribute11 IS NULL THEN
      x_trip_rec.attribute11 := p_trip_rec.attribute11;
    END IF;
    IF p_trip_rec.attribute12 <> FND_API.G_MISS_CHAR
      OR p_trip_rec.attribute12 IS NULL THEN
      x_trip_rec.attribute12 := p_trip_rec.attribute12;
    END IF;
    IF p_trip_rec.attribute13 <> FND_API.G_MISS_CHAR
      OR p_trip_rec.attribute13 IS NULL THEN
      x_trip_rec.attribute13 := p_trip_rec.attribute13;
    END IF;
    IF p_trip_rec.attribute14 <> FND_API.G_MISS_CHAR
      OR p_trip_rec.attribute14 IS NULL THEN
      x_trip_rec.attribute14 := p_trip_rec.attribute14;
    END IF;
    IF p_trip_rec.attribute15 <> FND_API.G_MISS_CHAR
      OR p_trip_rec.attribute15 IS NULL THEN
      x_trip_rec.attribute15 := p_trip_rec.attribute15;
    END IF;
    IF p_trip_rec.ATTRIBUTE_CATEGORY <> FND_API.G_MISS_CHAR
      OR p_trip_rec.ATTRIBUTE_CATEGORY IS NULL THEN
      x_trip_rec.ATTRIBUTE_CATEGORY := p_trip_rec.ATTRIBUTE_CATEGORY;
    END IF;
    -- OTM R12, glog project, allow GC3 Inbound Message to update tp_plan_name
    IF p_in_rec.caller IN ('WSH_TP_RELEASE','FTE_TMS_INTEGRATION') THEN
       IF p_trip_rec.tp_plan_name <> FND_API.G_MISS_CHAR
         OR p_trip_rec.tp_plan_name IS NULL THEN
         x_trip_rec.tp_plan_name := p_trip_rec.tp_plan_name;
       END IF;
       IF p_trip_rec.tp_trip_number <> FND_API.G_MISS_NUM
         OR p_trip_rec.tp_trip_number IS NULL THEN
         x_trip_rec.tp_trip_number := p_trip_rec.tp_trip_number;
       END IF;
    END IF;

    IF p_in_rec.caller IN ('FTE_ROUTING_GUIDE',
                           'FTE_RATING',
                           'FTE_LOAD_TENDER',
                           'FTE_MLS_WRAPPER') THEN

       IF p_trip_rec.rank_id <> FND_API.G_MISS_NUM
          OR p_trip_rec.rank_id IS NULL THEN
         x_trip_rec.rank_id := p_trip_rec.rank_id;
       END IF;

    END IF;

    IF p_in_rec.caller IN ('FTE_ROUTING_GUIDE',
                           'FTE_RATING',
                           'FTE_LOAD_TENDER') THEN

       IF p_trip_rec.routing_rule_id <> FND_API.G_MISS_NUM
          OR p_trip_rec.routing_rule_id IS NULL THEN
         x_trip_rec.routing_rule_id := p_trip_rec.routing_rule_id;
       END IF;

       IF p_trip_rec.append_flag <> FND_API.G_MISS_CHAR
          OR p_trip_rec.append_flag IS NULL THEN
         x_trip_rec.append_flag := p_trip_rec.append_flag;
       END IF;

    END IF;

   IF p_trip_rec.consignee_carrier_ac_no <> FND_API.G_MISS_CHAR
      OR p_trip_rec.consignee_carrier_ac_no IS NULL THEN
     x_trip_rec.consignee_carrier_ac_no := p_trip_rec.consignee_carrier_ac_no;
   END IF;

   IF p_trip_rec.carrier_reference_number <> FND_API.G_MISS_CHAR
      OR p_trip_rec.carrier_reference_number IS NULL THEN
     x_trip_rec.carrier_reference_number := p_trip_rec.carrier_reference_number;
   END IF;

   IF p_trip_rec.seal_code <> FND_API.G_MISS_CHAR
      OR p_trip_rec.seal_code IS NULL THEN
     x_trip_rec.seal_code := p_trip_rec.seal_code;
   END IF;

EXCEPTION
  -- OTM 12, glog proj, no debug or x_return_status variable here
  WHEN OTHERS THEN
   wsh_util_core.default_handler('WSH_TRIP_VALIDATIONS.ELIMINATE_DISPLAYONLY_FIELDS');

END eliminate_displayonly_fields;

/*----------------------------------------------------------
-- Procedure disable_from_list will update the record x_out_rec
-- and disables the field contained in p_disabled_list.
-----------------------------------------------------------*/

PROCEDURE disable_from_list(
  p_disabled_list IN         WSH_UTIL_CORE.column_tab_type
, p_in_rec        IN         WSH_TRIPS_PVT.trip_rec_type
, x_out_rec       IN OUT NOCOPY WSH_TRIPS_PVT.trip_rec_type
, x_return_status OUT NOCOPY        VARCHAR2
, x_field_name    OUT NOCOPY        VARCHAR2

) IS
BEGIN
  FOR i IN 1..p_disabled_list.COUNT
  LOOP
    IF p_disabled_list(i)  = 'ROUTING_INSTRUCTIONS' THEN
      x_out_rec.ROUTING_INSTRUCTIONS := p_in_rec.ROUTING_INSTRUCTIONS ;
    ELSIF p_disabled_list(i)  = 'FREIGHT_CODE' THEN
      --x_out_rec.FREIGHT_TERMS_CODE := p_in_rec.FREIGHT_TERMS_CODE ;
      x_out_rec.carrier_id      := p_in_rec.carrier_id;    -- J-IB-NPARIKH--I-bug-fix
    ELSIF p_disabled_list(i)  = 'SERVICE_LEVEL_NAME' THEN
      x_out_rec.SERVICE_LEVEL := p_in_rec.SERVICE_LEVEL ;
    ELSIF p_disabled_list(i)  = 'MODE_OF_TRANSPORT_NAME' THEN
      x_out_rec.MODE_OF_TRANSPORT := p_in_rec.MODE_OF_TRANSPORT ;
    ELSIF p_disabled_list(i)  = 'OPERATOR' THEN
      x_out_rec.OPERATOR := p_in_rec.OPERATOR ;
    ELSIF p_disabled_list(i)  = 'DESC_FLEX' THEN
      x_out_rec.attribute1 := p_in_rec.attribute1 ;
      x_out_rec.attribute2 := p_in_rec.attribute2 ;
      x_out_rec.attribute3 := p_in_rec.attribute3 ;
      x_out_rec.attribute4 := p_in_rec.attribute4 ;
      x_out_rec.attribute5 := p_in_rec.attribute5 ;
      x_out_rec.attribute6 := p_in_rec.attribute6 ;
      x_out_rec.attribute7 := p_in_rec.attribute7 ;
      x_out_rec.attribute8 := p_in_rec.attribute8 ;
      x_out_rec.attribute9 := p_in_rec.attribute9 ;
      x_out_rec.attribute10 := p_in_rec.attribute10 ;
      x_out_rec.attribute11 := p_in_rec.attribute11 ;
      x_out_rec.attribute12 := p_in_rec.attribute12 ;
      x_out_rec.attribute13 := p_in_rec.attribute13 ;
      x_out_rec.attribute14 := p_in_rec.attribute14 ;
      x_out_rec.attribute15 := p_in_rec.attribute15 ;
      x_out_rec.attribute_category := p_in_rec.attribute_category ;
    ELSIF p_disabled_list(i) = 'CARRIER_REFERENCE_NUMBER' THEN
      x_out_rec.carrier_reference_number := p_in_rec.carrier_reference_number;
    ELSIF p_disabled_list(i) = 'CONSIGNEE_CARRIER_AC_NO' THEN
      x_out_rec.consignee_carrier_ac_no := p_in_rec.consignee_carrier_ac_no;
    ELSIF p_disabled_list(i) = 'VEHICLE_NUM_PREFIX' THEN
      x_out_rec.vehicle_num_prefix := p_in_rec.vehicle_num_prefix;
    ELSIF p_disabled_list(i) = 'VEHICLE_ITEM_ID' THEN
      --DBMS_OUTPUT.PUT_LINE($$PLSQL_LINE);
      --DBMS_OUTPUT.PUT_LINE('VEHICLE_ITEM_ID:'||p_in_rec.vehicle_item_id);
      x_out_rec.vehicle_item_id := p_in_rec.vehicle_item_id;
    ELSIF p_disabled_list(i) = 'VEHICLE_ORGANIZATION_CODE' THEN
      x_out_rec.vehicle_organization_code := p_in_rec.vehicle_organization_code;
    ELSIF p_disabled_list(i) = 'VEHICLE_NUMBER' THEN
      x_out_rec.vehicle_number := p_in_rec.vehicle_number;
    ELSIF p_disabled_list(i) = 'VEHICLE_ITEM_NAME' THEN
     -- VEHICLE_ITEM_NAME is just a ui field and doesn't exist in table
       NULL;
    ELSIF  p_disabled_list(i)  = 'FULL' THEN
      NULL;
    ELSE
      -- invalid name
      x_field_name := p_disabled_list(i);
      x_return_status := WSH_UTIL_CORE.G_RET_STS_ERROR;
      RETURN;
      --
    END IF;
  END LOOP;
END disable_from_list;
/*
   Procedure populate_external_efl is called from
   enable_from_list to populate the external value
   for a given internal field
*/

PROCEDURE populate_external_efl(
  p_internal        IN   VARCHAR2
, p_external        IN   VARCHAR2
, p_mode            IN   VARCHAR2
, x_internal        IN OUT  NOCOPY VARCHAR2
, x_external        IN OUT  NOCOPY VARCHAR2
)
IS
BEGIN

   IF p_mode = '+' THEN
      IF x_internal IS NULL THEN
         IF p_internal <> FND_API.G_MISS_CHAR OR p_internal IS NULL THEN
            x_internal := p_internal ;
            IF p_internal IS NULL THEN
               x_external := NULL;
            ELSE
               x_external := p_external;
            END IF;
         ELSIF p_external <> FND_API.G_MISS_CHAR OR p_external IS NULL THEN
            x_external := p_external;
            IF p_external IS NULL THEN
               x_internal := NULL;
            ELSE
               x_internal := p_internal;
            END IF;
         END IF;
      END IF;
   ELSE --p_mode <> +
      IF p_internal <> FND_API.G_MISS_CHAR OR p_internal IS NULL THEN
         x_internal := p_internal ;
         IF p_internal IS NULL THEN
            x_external := NULL;
         ELSE
            x_external := p_external;
         END IF;
      ELSIF p_external <> FND_API.G_MISS_CHAR OR p_external IS NULL THEN
         x_external := p_external;
         IF p_external IS NULL THEN
            x_internal := NULL;
         ELSE
            x_internal := p_internal;
         END IF;
      END IF;
   END IF;

END populate_external_efl;

/*
   Procedure populate_external_efl is called from
   enable_from_list to populate the external value
   for a given internal field
*/

PROCEDURE populate_external_efl(
  p_internal        IN   NUMBER
, p_external        IN   VARCHAR2
, p_mode            IN   VARCHAR2
, x_internal        IN OUT  NOCOPY NUMBER
, x_external        IN OUT  NOCOPY VARCHAR2
)
IS
BEGIN

   IF p_mode = '+' THEN
      IF x_internal IS NULL THEN
         IF p_internal <> FND_API.G_MISS_NUM OR p_internal IS NULL THEN
            x_internal := p_internal ;
            IF p_internal IS NULL THEN
               x_external := NULL;
            ELSE
               x_external := p_external;
            END IF;
         ELSIF p_external <> FND_API.G_MISS_CHAR OR p_external IS NULL THEN
            x_external := p_external;
            IF p_external IS NULL THEN
               x_internal := NULL;
            ELSE
               x_internal := p_internal;
            END IF;
         END IF;
      END IF;
   ELSE --p_mode <> +
      IF p_internal <> FND_API.G_MISS_NUM OR p_internal IS NULL THEN
         x_internal := p_internal ;
         IF p_internal IS NULL THEN
            x_external := NULL;
         ELSE
            x_external := p_external;
         END IF;
      ELSIF p_external <> FND_API.G_MISS_CHAR OR p_external IS NULL THEN
         x_external := p_external;
         IF p_external IS NULL THEN
            x_internal := NULL;
         ELSE
            x_internal := p_internal;
         END IF;
      END IF;
   END IF;

END populate_external_efl;
/*----------------------------------------------------------
-- Procedure enable_from_list will update the record x_out_rec for the fields
--   included in p_disabled_list and will enable them
-----------------------------------------------------------*/

PROCEDURE enable_from_list(
  p_disabled_list IN         WSH_UTIL_CORE.column_tab_type
, p_in_rec        IN         WSH_TRIPS_PVT.trip_rec_type
, x_out_rec       IN OUT NOCOPY WSH_TRIPS_PVT.trip_rec_type
, x_return_status OUT NOCOPY        VARCHAR2
, x_field_name    OUT NOCOPY        VARCHAR2

) IS
BEGIN
  --DBMS_OUTPUT.PUT_LINE($$PLSQL_LINE);
  FOR i IN 2..p_disabled_list.COUNT LOOP
    --DBMS_OUTPUT.PUT_LINE(' '||p_disabled_list(i));
    IF p_disabled_list(i)  = 'ROUTING_INSTRUCTIONS' THEN
     IF p_in_rec.ROUTING_INSTRUCTIONS <> FND_API.G_MISS_CHAR OR p_in_rec.ROUTING_INSTRUCTIONS IS NULL THEN
      x_out_rec.ROUTING_INSTRUCTIONS := p_in_rec.ROUTING_INSTRUCTIONS ;
     END IF;
    -- J-IB-NPARIKH-{ ---I-bug-fix
    ELSIF p_disabled_list(i)  = 'FREIGHT_CODE' THEN
     IF p_in_rec.CARRIER_ID <> FND_API.G_MISS_NUM OR p_in_rec.CARRIER_ID IS NULL THEN
      x_out_rec.CARRIER_ID := p_in_rec.CARRIER_ID ;
     END IF;
    ELSIF p_disabled_list(i)  = '+FREIGHT_CODE' THEN
     IF p_in_rec.CARRIER_ID <> FND_API.G_MISS_NUM OR p_in_rec.CARRIER_ID IS NULL THEN
        IF x_out_rec.CARRIER_ID IS NULL THEN
          x_out_rec.CARRIER_ID := p_in_rec.CARRIER_ID ;
        END IF;
     END IF;
    ELSIF p_disabled_list(i)  = '+SHIP_METHOD_NAME' THEN
     populate_external_efl(p_in_rec.ship_method_code,
                           p_in_rec.ship_method_name,
                           '+',
                           x_out_rec.ship_method_code,
                           x_out_rec.ship_method_name);
    ELSIF p_disabled_list(i)  = 'SHIP_METHOD_NAME' THEN
     populate_external_efl(p_in_rec.ship_method_code,
                           p_in_rec.ship_method_name,
                           NULL,
                           x_out_rec.ship_method_code,
                           x_out_rec.ship_method_name);

     -- J-IB-NPARIKH-}

     /*
     IF p_in_rec.FREIGHT_TERMS_CODE <> FND_API.G_MISS_CHAR
       OR p_in_rec.FREIGHT_TERMS_CODE IS NULL THEN
      x_out_rec.FREIGHT_TERMS_CODE := p_in_rec.FREIGHT_TERMS_CODE ;
     END IF;
     */
    ELSIF p_disabled_list(i)  = 'SERVICE_LEVEL_NAME' THEN
     IF p_in_rec.SERVICE_LEVEL <> FND_API.G_MISS_CHAR OR p_in_rec.SERVICE_LEVEL IS NULL THEN
       x_out_rec.SERVICE_LEVEL := p_in_rec.SERVICE_LEVEL ;
     END IF;
    ELSIF p_disabled_list(i)  = 'MODE_OF_TRANSPORT_NAME' THEN
     IF p_in_rec.MODE_OF_TRANSPORT <> FND_API.G_MISS_CHAR OR p_in_rec.MODE_OF_TRANSPORT IS NULL THEN
        x_out_rec.MODE_OF_TRANSPORT := p_in_rec.MODE_OF_TRANSPORT ;
     END IF;
    -- J-IB-NPARIKH-{
    ELSIF p_disabled_list(i)  = '+SERVICE_LEVEL_NAME' THEN
     IF p_in_rec.SERVICE_LEVEL <> FND_API.G_MISS_CHAR
      OR p_in_rec.SERVICE_LEVEL IS NULL THEN
        IF x_out_rec.SERVICE_LEVEL IS NULL THEN
          x_out_rec.SERVICE_LEVEL := p_in_rec.SERVICE_LEVEL ;
        END IF;
     END IF;
    ELSIF p_disabled_list(i)  = '+MODE_OF_TRANSPORT_NAME' THEN
     IF p_in_rec.MODE_OF_TRANSPORT <> FND_API.G_MISS_CHAR OR p_in_rec.MODE_OF_TRANSPORT IS NULL THEN
        IF x_out_rec.MODE_OF_TRANSPORT IS NULL THEN
          x_out_rec.MODE_OF_TRANSPORT := p_in_rec.MODE_OF_TRANSPORT ;
        END IF;
     END IF;
    ELSIF p_disabled_list(i)  = '+LANE_ID' THEN
     IF p_in_rec.LANE_ID <> FND_API.G_MISS_NUM OR p_in_rec.LANE_ID IS NULL THEN
        IF x_out_rec.LANE_ID IS NULL THEN
          x_out_rec.LANE_ID := p_in_rec.LANE_ID ;
        END IF;
     END IF;
    ELSIF p_disabled_list(i)  = 'VEHICLE_NUMBER' THEN
     IF p_in_rec.VEHICLE_NUMBER <> FND_API.G_MISS_CHAR OR p_in_rec.VEHICLE_NUMBER IS NULL THEN
        x_out_rec.VEHICLE_NUMBER := p_in_rec.VEHICLE_NUMBER ;
     END IF;
    ELSIF p_disabled_list(i)  = 'VEHICLE_NUM_PREFIX' THEN
     IF p_in_rec.VEHICLE_NUM_PREFIX <> FND_API.G_MISS_CHAR OR p_in_rec.VEHICLE_NUM_PREFIX IS NULL THEN
        x_out_rec.VEHICLE_NUM_PREFIX := p_in_rec.VEHICLE_NUM_PREFIX ;
     END IF;
    -- OTM R12, glog project
    ELSIF p_disabled_list(i)  = 'SEAL_CODE' THEN
     IF p_in_rec.SEAL_CODE <> FND_API.G_MISS_CHAR OR p_in_rec.SEAL_CODE IS NULL THEN
        x_out_rec.SEAL_CODE := p_in_rec.SEAL_CODE;
     END IF;
    ELSIF p_disabled_list(i)  = 'NAME' THEN
     IF p_in_rec.NAME <> FND_API.G_MISS_CHAR OR p_in_rec.NAME IS NULL THEN
        x_out_rec.NAME := p_in_rec.NAME;
     END IF;
    -- OTM R12, end of glog project
    ELSIF p_disabled_list(i)  = 'OPERATOR' THEN
     IF p_in_rec.OPERATOR <> FND_API.G_MISS_CHAR OR p_in_rec.OPERATOR IS NULL THEN
        x_out_rec.OPERATOR := p_in_rec.OPERATOR ;
     END IF;
    -- bug 3507047: Enable update of lane on firmed trip.
    ELSIF p_disabled_list(i)  = 'LANE_ID' THEN
     IF p_in_rec.LANE_ID <> FND_API.G_MISS_NUM OR p_in_rec.LANE_ID IS NULL THEN
        x_out_rec.LANE_ID := p_in_rec.LANE_ID ;
     END IF;
     -- J-IB-NPARIKH-}
    ELSIF p_disabled_list(i)  = 'DESC_FLEX' THEN
     IF p_in_rec.attribute1 <> FND_API.G_MISS_CHAR OR p_in_rec.attribute1 IS NULL THEN
      x_out_rec.attribute1 := p_in_rec.attribute1 ;
     END IF;
     IF p_in_rec.attribute2 <> FND_API.G_MISS_CHAR OR p_in_rec.attribute2 IS NULL THEN
      x_out_rec.attribute2 := p_in_rec.attribute2 ;
     END IF;
     IF p_in_rec.attribute3 <> FND_API.G_MISS_CHAR OR p_in_rec.attribute3 IS NULL THEN
      x_out_rec.attribute3 := p_in_rec.attribute3 ;
     END IF;
     IF p_in_rec.attribute4 <> FND_API.G_MISS_CHAR OR p_in_rec.attribute4 IS NULL THEN
      x_out_rec.attribute4 := p_in_rec.attribute4 ;
     END IF;
     IF p_in_rec.attribute5 <> FND_API.G_MISS_CHAR OR p_in_rec.attribute5 IS NULL THEN
      x_out_rec.attribute5 := p_in_rec.attribute5 ;
     END IF;
     IF p_in_rec.attribute6 <> FND_API.G_MISS_CHAR OR p_in_rec.attribute6 IS NULL THEN
      x_out_rec.attribute6 := p_in_rec.attribute6 ;
     END IF;
     IF p_in_rec.attribute7 <> FND_API.G_MISS_CHAR OR p_in_rec.attribute7 IS NULL THEN
      x_out_rec.attribute7 := p_in_rec.attribute7 ;
     END IF;
     IF p_in_rec.attribute8 <> FND_API.G_MISS_CHAR OR p_in_rec.attribute8 IS NULL THEN
      x_out_rec.attribute8 := p_in_rec.attribute8 ;
     END IF;
     IF p_in_rec.attribute9 <> FND_API.G_MISS_CHAR OR p_in_rec.attribute9 IS NULL THEN
      x_out_rec.attribute9 := p_in_rec.attribute9 ;
     END IF;
     IF p_in_rec.attribute10 <> FND_API.G_MISS_CHAR OR p_in_rec.attribute10 IS NULL THEN
      x_out_rec.attribute10 := p_in_rec.attribute10 ;
     END IF;
     IF p_in_rec.attribute11 <> FND_API.G_MISS_CHAR OR p_in_rec.attribute11 IS NULL THEN
      x_out_rec.attribute11 := p_in_rec.attribute11 ;
     END IF;
     IF p_in_rec.attribute12 <> FND_API.G_MISS_CHAR OR p_in_rec.attribute12 IS NULL THEN
      x_out_rec.attribute12 := p_in_rec.attribute12 ;
     END IF;
     IF p_in_rec.attribute13 <> FND_API.G_MISS_CHAR OR p_in_rec.attribute13 IS NULL THEN
      x_out_rec.attribute13 := p_in_rec.attribute13 ;
     END IF;
     IF p_in_rec.attribute14 <> FND_API.G_MISS_CHAR OR p_in_rec.attribute14 IS NULL THEN
      x_out_rec.attribute14 := p_in_rec.attribute14 ;
     END IF;
     IF p_in_rec.attribute15 <> FND_API.G_MISS_CHAR OR p_in_rec.attribute15 IS NULL THEN
      x_out_rec.attribute15 := p_in_rec.attribute15 ;
     END IF;
     IF p_in_rec.attribute_category <> FND_API.G_MISS_CHAR OR p_in_rec.attribute_category IS NULL THEN
      x_out_rec.attribute_category := p_in_rec.attribute_category ;
     END IF;
    --ELSIF  p_disabled_list(i)  = 'FULL'  THEN
      --NULL;
    --bug 3257612 : load tender needs to update fields even if firm
    ELSIF p_disabled_list(i)  = 'LOAD_TENDER_STATUS' THEN
     IF p_in_rec.LOAD_TENDER_STATUS <> FND_API.G_MISS_CHAR OR p_in_rec.LOAD_TENDER_STATUS IS NULL THEN
        x_out_rec.LOAD_TENDER_STATUS := p_in_rec.LOAD_TENDER_STATUS;
     END IF;
    ELSIF p_disabled_list(i)  = 'WF_NAME' THEN
     IF p_in_rec.WF_NAME <> FND_API.G_MISS_CHAR OR p_in_rec.WF_NAME IS NULL THEN
        x_out_rec.WF_NAME := p_in_rec.WF_NAME;
     END IF;
    ELSIF p_disabled_list(i)  = 'WF_PROCESS_NAME' THEN
     IF p_in_rec.WF_PROCESS_NAME <> FND_API.G_MISS_CHAR  OR p_in_rec.WF_PROCESS_NAME IS NULL THEN
        x_out_rec.WF_PROCESS_NAME := p_in_rec.WF_PROCESS_NAME;
     END IF;
    ELSIF p_disabled_list(i)  = 'WF_ITEM_KEY' THEN
     IF p_in_rec.WF_ITEM_KEY <> FND_API.G_MISS_CHAR OR p_in_rec.WF_ITEM_KEY IS NULL THEN
        x_out_rec.WF_ITEM_KEY := p_in_rec.WF_ITEM_KEY;
     END IF;
    ELSIF p_disabled_list(i)  = 'CARRIER_CONTACT_ID' THEN
     IF p_in_rec.CARRIER_CONTACT_ID <> FND_API.G_MISS_NUM OR p_in_rec.CARRIER_CONTACT_ID IS NULL THEN
        x_out_rec.CARRIER_CONTACT_ID := p_in_rec.CARRIER_CONTACT_ID;
     END IF;
    ELSIF p_disabled_list(i)  = 'SHIPPER_WAIT_TIME' THEN
     IF p_in_rec.SHIPPER_WAIT_TIME <> FND_API.G_MISS_NUM OR p_in_rec.SHIPPER_WAIT_TIME IS NULL THEN
        x_out_rec.SHIPPER_WAIT_TIME := p_in_rec.SHIPPER_WAIT_TIME ;
     END IF;
    ELSIF p_disabled_list(i)  = 'WAIT_TIME_UOM' THEN
     IF p_in_rec.WAIT_TIME_UOM <> FND_API.G_MISS_CHAR  OR p_in_rec.WAIT_TIME_UOM IS NULL THEN
        x_out_rec.WAIT_TIME_UOM := p_in_rec.WAIT_TIME_UOM ;
     END IF;
    ELSIF p_disabled_list(i)  = 'LOAD_TENDERED_TIME' THEN
     IF p_in_rec.LOAD_TENDERED_TIME <> FND_API.G_MISS_DATE OR p_in_rec.LOAD_TENDERED_TIME IS NULL THEN
        x_out_rec.LOAD_TENDERED_TIME := p_in_rec.LOAD_TENDERED_TIME;
     END IF;
    ELSIF p_disabled_list(i)  = 'CARRIER_RESPONSE' THEN
     IF p_in_rec.CARRIER_RESPONSE <> FND_API.G_MISS_CHAR OR p_in_rec.CARRIER_RESPONSE IS NULL THEN
        x_out_rec.CARRIER_RESPONSE := p_in_rec.CARRIER_RESPONSE;
     END IF;
    --Bug 3309150 {
    ELSIF p_disabled_list(i)  = 'VEHICLE_ORGANIZATION_CODE' THEN
     populate_external_efl(p_in_rec.VEHICLE_ORGANIZATION_ID,
                           p_in_rec.VEHICLE_ORGANIZATION_CODE,
                           NULL,
                           x_out_rec.VEHICLE_ORGANIZATION_ID,
                           x_out_rec.VEHICLE_ORGANIZATION_CODE);


     --Bug 3599626: If veh. org is enabled, enable the veh. item as well {
     IF x_out_rec.VEHICLE_ORGANIZATION_ID IS NOT NULL THEN
       --DBMS_OUTPUT.PUT_LINE($$PLSQL_LINE);
       IF p_in_rec.VEHICLE_ITEM_ID <> FND_API.G_MISS_NUM OR p_in_rec.VEHICLE_ITEM_ID IS NULL THEN
         --DBMS_OUTPUT.PUT_LINE($$PLSQL_LINE);
         x_out_rec.VEHICLE_ITEM_ID := p_in_rec.VEHICLE_ITEM_ID;
       END IF;
     END IF;

    --}
    --Bug 3599626 {
    ELSIF p_disabled_list(i)  = 'VEHICLE_ITEM_NAME' THEN
          -- This is already handled when enabling 'VEHICLE_ORGANIZATION_CODE'
          -- but we do not want to raise the below error.
          NULL;
    --}
    ELSIF p_disabled_list(i) = 'CARRIER_REFERENCE_NUMBER' THEN
      IF p_in_rec.CARRIER_REFERENCE_NUMBER <> FND_API.G_MISS_CHAR OR p_in_rec.CARRIER_REFERENCE_NUMBER IS NULL  THEN
         x_out_rec.CARRIER_REFERENCE_NUMBER := p_in_rec.CARRIER_REFERENCE_NUMBER;
      END IF;
    ELSIF p_disabled_list(i) = '+CARRIER_REFERENCE_NUMBER' THEN
      IF p_in_rec.CARRIER_REFERENCE_NUMBER <> FND_API.G_MISS_CHAR OR p_in_rec.CARRIER_REFERENCE_NUMBER IS NULL  THEN
         IF x_out_rec.CARRIER_REFERENCE_NUMBER IS NULL THEN
           x_out_rec.CARRIER_REFERENCE_NUMBER := p_in_rec.CARRIER_REFERENCE_NUMBER;
         END IF;
      END IF;
    ELSIF p_disabled_list(i) = 'CONSIGNEE_CARRIER_AC_NO' THEN
      IF p_in_rec.CONSIGNEE_CARRIER_AC_NO <> FND_API.G_MISS_CHAR OR p_in_rec.CONSIGNEE_CARRIER_AC_NO IS NULL  THEN
         x_out_rec.CONSIGNEE_CARRIER_AC_NO := p_in_rec.CONSIGNEE_CARRIER_AC_NO;
      END IF;
    ELSIF p_disabled_list(i) = '+CONSIGNEE_CARRIER_AC_NO' THEN
      IF p_in_rec.CONSIGNEE_CARRIER_AC_NO <> FND_API.G_MISS_CHAR OR p_in_rec.CONSIGNEE_CARRIER_AC_NO IS NULL  THEN
         IF x_out_rec.CONSIGNEE_CARRIER_AC_NO IS NULL THEN
           x_out_rec.CONSIGNEE_CARRIER_AC_NO := p_in_rec.CONSIGNEE_CARRIER_AC_NO;
         END IF;
      END IF;
    ELSIF p_disabled_list(i) IN ('+FREIGHT_TERMS_CODE', '+FREIGHT_TERMS_NAME')  THEN
      IF p_in_rec.FREIGHT_TERMS_CODE <> FND_API.G_MISS_CHAR OR p_in_rec.FREIGHT_TERMS_CODE IS NULL  THEN
         IF x_out_rec.FREIGHT_TERMS_CODE IS NULL THEN
           x_out_rec.FREIGHT_TERMS_CODE := p_in_rec.FREIGHT_TERMS_CODE;
         END IF;
      END IF;
    ELSE
      --DBMS_OUTPUT.PUT_LINE($$PLSQL_LINE);
      -- invalid name
      x_field_name := p_disabled_list(i);
      x_return_status := WSH_UTIL_CORE.G_RET_STS_ERROR;
      RETURN;
      --
    END IF;
  END LOOP;

EXCEPTION
  -- OTM R12, glog proj, add when Others exception handler
  WHEN others THEN
    wsh_util_core.default_handler('WSH_TRIP_VALIDATIONS.ENABLE_FROM_LIST');
    x_return_status := WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR;

END enable_from_list;

--
-- Overloaded procedure
-- Bug 2678363: Added new parameter p_in_rec, in place of p_action
--
PROCEDURE Get_Disabled_List  (
  p_trip_rec          IN  WSH_TRIPS_PVT.trip_rec_type
, p_in_rec	      IN  WSH_TRIPS_GRP.TripInRecType
, x_return_status     OUT NOCOPY VARCHAR2
, x_msg_count         OUT NOCOPY NUMBER
, x_msg_data          OUT NOCOPY VARCHAR2
, x_trip_rec          OUT NOCOPY WSH_TRIPS_PVT.trip_rec_type
)
IS
  l_disabled_list               WSH_UTIL_CORE.column_tab_type;
  l_db_col_rec                  WSH_TRIPS_PVT.trip_rec_type;
  l_return_status               VARCHAR2(30);
  l_field_name                  VARCHAR2(100);
  l_debug_on BOOLEAN;
  l_module_name CONSTANT VARCHAR2(100) := 'wsh.plsql.' || G_PKG_NAME || '.' || 'GET_DISABLED_LIST';


  e_dp_no_entity EXCEPTION;
  e_bad_field EXCEPTION;
  e_all_disabled EXCEPTION ;

  l_caller               VARCHAR2(32767);
  --
  i number;

BEGIN
  --
  l_debug_on := WSH_DEBUG_INTERFACE.g_debug;
  --
  IF l_debug_on IS NULL
  THEN
      l_debug_on := WSH_DEBUG_SV.is_debug_enabled;
  END IF;
  --
  IF l_debug_on THEN
    --
    WSH_DEBUG_SV.push(l_module_name);
    WSH_DEBUG_SV.log(l_module_name,'trip_id',p_trip_rec.trip_id);
    WSH_DEBUG_SV.log(l_module_name,'Action', p_in_rec.action_code);
    WSH_DEBUG_SV.log(l_module_name,'Caller', p_in_rec.caller);
    --
  END IF;
  --
  x_return_status := FND_API.G_RET_STS_SUCCESS;
  --
  IF p_in_rec.action_code = 'CREATE' THEN
     --
     IF l_debug_on THEN
         WSH_DEBUG_SV.log(l_module_name,'calling eliminate_displayonly_fields');
     END IF;
     --
     -- nothing else need to be disabled
     --
     eliminate_displayonly_fields (p_trip_rec,p_in_rec,x_trip_rec);
     --
     --3509004:public api changes
/*
     IF l_debug_on THEN
       WSH_DEBUG_SV.log(l_module_name,'x_return_status',x_return_status);
       WSH_DEBUG_SV.pop(l_module_name);
     END IF;
     -- RETURN;
     --
*/
  ELSIF p_in_rec.action_code = 'UPDATE' THEN
   --
    --DBMS_OUTPUT.PUT_LINE($$PLSQL_LINE);
    l_caller := p_in_rec.caller;
    --DBMS_OUTPUT.PUT_LINE(l_caller);
    IF (l_caller like 'FTE%') THEN
      l_caller := 'WSH_PUB';
    END IF;
   Get_Disabled_List( p_trip_rec.trip_id
                     , 'FORM'
                     , x_return_status
                     , l_disabled_list
                     , x_msg_count
                     , x_msg_data
		     , l_caller --3509004:public api changes
                     );
   --
   IF x_return_status = WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR OR
     x_return_status = WSH_UTIL_CORE.G_RET_STS_ERROR
   THEN
    --
    IF l_debug_on THEN
      WSH_DEBUG_SV.log(l_module_name,'x_return_status',x_return_status);
      WSH_DEBUG_SV.pop(l_module_name);
    END IF;
    RETURN;
    --
   END IF;
   --
   IF l_disabled_list.COUNT = 1 THEN
     IF l_disabled_list(1) = 'FULL' THEN
       RAISE e_all_disabled;
      --Everything  is disabled
     END IF;
   END IF;
   --

   WSH_TRIPS_PVT.populate_record(
             p_trip_id       => p_trip_rec.trip_id,
             x_trip_info     => x_trip_rec,
             x_return_status => x_return_status);

   IF (x_return_status IN (WSH_UTIL_CORE.G_RET_STS_ERROR,
                           WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR))  THEN
     RAISE e_dp_no_entity;
   END IF;

   --
   -- bug 3398603: TP Release needs to always update these fields
   --     even if the trip is firmed.

   -- OTM R12, glog project, allow GC3 Inbound Message to update tp_plan_name
   -- no change required for CREATE, caller = FTE_TMS_INTEGRATION
   IF p_in_rec.caller IN ('WSH_TP_RELEASE','FTE_TMS_INTEGRATION') THEN--{
     IF p_trip_rec.tp_plan_name <> FND_API.G_MISS_CHAR
         OR p_trip_rec.tp_plan_name IS NULL THEN
       x_trip_rec.tp_plan_name := p_trip_rec.tp_plan_name;
     END IF;
     IF p_trip_rec.tp_trip_number <> FND_API.G_MISS_NUM
         OR p_trip_rec.tp_trip_number IS NULL THEN
       x_trip_rec.tp_trip_number := p_trip_rec.tp_trip_number;
     END IF;
   END IF;--}
   -- OTM R12, glog proj,GC3 inbound message can also update Mode, Service, Carrier,Freight
   -- Ship Method Code, Vehicle Item id + Organization
   IF p_in_rec.caller = 'FTE_TMS_INTEGRATION' THEN --{
     IF p_trip_rec.mode_of_transport <> FND_API.G_MISS_CHAR
        OR p_trip_rec.mode_of_transport IS NULL THEN
       x_trip_rec.mode_of_transport := p_trip_rec.mode_of_transport;
     END IF;
     IF p_trip_rec.service_level <> FND_API.G_MISS_CHAR
        OR p_trip_rec.service_level IS NULL THEN
       x_trip_rec.service_level := p_trip_rec.service_level;
     END IF;
     IF p_trip_rec.carrier_id <> FND_API.G_MISS_NUM
        OR p_trip_rec.carrier_id IS NULL THEN
       x_trip_rec.carrier_id := p_trip_rec.carrier_id;
     END IF;
     IF p_trip_rec.freight_terms_code <> FND_API.G_MISS_CHAR
        OR p_trip_rec.freight_terms_code IS NULL THEN
       x_trip_rec.freight_terms_code := p_trip_rec.freight_terms_code;
     END IF;
     IF p_trip_rec.ship_method_code <> FND_API.G_MISS_CHAR
        OR p_trip_rec.ship_method_code IS NULL THEN
       x_trip_rec.ship_method_code := p_trip_rec.ship_method_code;
     END IF;
     IF p_trip_rec.vehicle_item_id <> FND_API.G_MISS_NUM OR p_trip_rec.vehicle_item_id IS NULL THEN
       --DBMS_OUTPUT.PUT_LINE($$PLSQL_LINE);
       x_trip_rec.vehicle_item_id := p_trip_rec.vehicle_item_id;
     END IF;
     IF p_trip_rec.vehicle_organization_id <> FND_API.G_MISS_NUM
        OR p_trip_rec.vehicle_organization_id IS NULL THEN
       x_trip_rec.vehicle_organization_id := p_trip_rec.vehicle_organization_id;
     END IF;
   END IF;--}

   -- End of code added for OTM R12, glog proj
   --

   --
   --
   IF l_debug_on THEN
     WSH_DEBUG_SV.log(l_module_name,'list.COUNT',l_disabled_list.COUNT);
   END IF;
   --
   IF l_disabled_list.COUNT = 0 THEN
     --
     IF l_debug_on THEN
         WSH_DEBUG_SV.log(l_module_name,'calling eliminate_displayonly_fields');
     END IF;
     --
     -- nothing else need to be disabled
     --
     eliminate_displayonly_fields (p_trip_rec,p_in_rec,x_trip_rec);

   ELSIF l_disabled_list(1) = 'FULL' THEN
     --
     IF l_disabled_list.COUNT > 1 THEN
      --
      IF l_debug_on THEN
        FOR i in 1..l_disabled_list.COUNT LOOP
          WSH_DEBUG_SV.log(l_module_name,'list values',l_disabled_list(i));
        END LOOP;
        WSH_DEBUG_SV.log(l_module_name,'calling enable_from_list');
      END IF;
      --enable the columns matching the l_disabled_list
      --DBMS_OUTPUT.PUT_LINE($$PLSQL_LINE);
      enable_from_list(l_disabled_list,
                      p_trip_rec,
                      x_trip_rec,
                      l_return_status,
                      l_field_name);
      IF l_return_status = WSH_UTIL_CORE.G_RET_STS_ERROR THEN
        --DBMS_OUTPUT.PUT_LINE($$PLSQL_LINE);
        RAISE e_bad_field;
      END IF;
      --
    END IF;
    --
   ELSE -- list.count > 1 and list(1) <> 'FULL'
    --
    l_db_col_rec := x_trip_rec ;
    --
    IF l_debug_on THEN
        FOR i in 1..l_disabled_list.COUNT
        LOOP
          WSH_DEBUG_SV.log(l_module_name,'list values',l_disabled_list(i));
        END LOOP;
        WSH_DEBUG_SV.log(l_module_name,'First element is not FULL');
        WSH_DEBUG_SV.log(l_module_name,'calling eliminate_displayonly_fields');
    END IF;
    --
    eliminate_displayonly_fields (p_trip_rec,p_in_rec,x_trip_rec);
    --
    IF l_debug_on THEN
        WSH_DEBUG_SV.log(l_module_name,'calling disable_from_list');
    END IF;
    -- The fileds in the list are getting disabled
    disable_from_list(l_disabled_list,
                      l_db_col_rec,
                      x_trip_rec,
                      l_return_status,
                      l_field_name
                      );
    IF l_return_status = WSH_UTIL_CORE.G_RET_STS_ERROR THEN
      --DBMS_OUTPUT.PUT_LINE('A2');
       RAISE e_bad_field;
    END IF;
    --
   END IF;
   --
  END IF; /* if action = 'UPDATE' */
  --3509004:public api changes
  IF (nvl(p_in_rec.caller,'''') <> 'WSH_FSTRX' AND
      nvl(p_in_rec.caller,'''') NOT LIKE 'DYMS%' AND -- DYMS Changes
      nvl(p_in_rec.caller,'''') NOT LIKE 'FTE%') THEN
    --
    user_non_updatable_columns
      (p_user_in_rec   => p_trip_rec,
       p_out_rec       => x_trip_rec,
       p_in_rec        => p_in_rec,
       x_return_status => l_return_status);
    --
    IF l_return_status = WSH_UTIL_CORE.G_RET_STS_ERROR THEN
       x_return_status := l_return_status;
    END IF;
    --
  END IF;
  --
  IF l_debug_on THEN
    WSH_DEBUG_SV.pop(l_module_name);
  END IF;
  --
  EXCEPTION
    WHEN e_all_disabled THEN
      x_return_status := WSH_UTIL_CORE.G_RET_STS_ERROR;
      FND_MESSAGE.SET_NAME('WSH','WSH_ALL_COLS_DISABLED');
      FND_MESSAGE.Set_Token('ENTITY_ID',p_trip_rec.trip_id);
      wsh_util_core.add_message(x_return_status,l_module_name);
      IF l_debug_on THEN
        -- Nothing is updateable
        WSH_DEBUG_SV.pop(l_module_name,'e_all_disabled');
      END IF;
    WHEN e_dp_no_entity THEN
      x_return_status := WSH_UTIL_CORE.G_RET_STS_ERROR;
      -- the message for this is set in original get_disabled_list
      IF l_debug_on THEN
        WSH_DEBUG_SV.pop(l_module_name,'e_dp_no_entity');
      END IF;
    WHEN e_bad_field THEN
      x_return_status := WSH_UTIL_CORE.G_RET_STS_ERROR;
      FND_MESSAGE.SET_NAME('WSH','WSH_BAD_FIELD_NAME');
      FND_MESSAGE.Set_Token('FIELD_NAME',l_field_name);
      wsh_util_core.add_message(x_return_status,l_module_name);
      IF l_debug_on THEN
        WSH_DEBUG_SV.log(l_module_name,'Bad field name passed to the list:'
                                                        ,l_field_name);
        WSH_DEBUG_SV.pop(l_module_name,'e_bad_field');
      END IF;

    WHEN OTHERS THEN
      wsh_util_core.default_handler('WSH_DETAILS_VALIDATIONS.get_disabled_list'
                                        ,l_module_name);
      x_return_status := WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR;
      IF l_debug_on THEN
        WSH_DEBUG_SV.log(l_module_name,'Error:',SUBSTR(SQLERRM,1,200));
        WSH_DEBUG_SV.pop(l_module_name,'EXCEPTION:OTHERS');
      END IF;
END Get_Disabled_List;



PROCEDURE Init_Trip_Actions_Tbl (
  p_action                   IN                VARCHAR2
, x_Trip_actions_tab         OUT     NOCOPY          TripActionsTabType
, x_return_status            OUT     NOCOPY          VARCHAR2
)

IS
  l_debug_on         BOOLEAN;
  l_module_name      CONSTANT VARCHAR2(100) :=
         'wsh.plsql.' || G_PKG_NAME || '.' || 'Init_Trip_Actions_Tbl';
  i                  NUMBER := 0;

  l_gc3_is_installed VARCHAR(1); --OTM R12, glog proj

BEGIN
  --
  l_debug_on := WSH_DEBUG_INTERFACE.g_debug;
  --
  IF l_debug_on IS NULL
  THEN
      l_debug_on := WSH_DEBUG_SV.is_debug_enabled;
  END IF;

  --OTM R12, glog proj, use Global Variable
  l_gc3_is_installed := WSH_UTIL_CORE.G_GC3_IS_INSTALLED;

  -- If null, call the function
  IF l_gc3_is_installed IS NULL THEN
    l_gc3_is_installed := WSH_UTIL_CORE.GC3_IS_INSTALLED;
  END IF;
  -- end of OTM R12, glog proj


  --
  -- J-IB-NPARIKH-{
  --
  -- Disable all actions on inbound stops when called from transactions form
  --
    i := i+1;
    x_Trip_actions_tab(i).shipments_type_flag    := 'I';
    x_Trip_actions_tab(i).caller             := 'WSH_FSTRX';
    x_Trip_actions_tab(i).action_not_allowed := p_action;
  -- J-IB-NPARIKH-}
  --
  IF p_action = 'TRIP-CONFIRM' THEN

    i := i + 1;
    x_Trip_actions_tab(i).action_not_allowed := 'TRIP-CONFIRM';
    x_Trip_actions_tab(i).status_code := 'IT';
    i := i + 1;
    x_Trip_actions_tab(i).action_not_allowed := 'TRIP-CONFIRM';
    x_Trip_actions_tab(i).status_code := 'CL';
    i := i + 1;
    x_Trip_actions_tab(i).action_not_allowed := 'TRIP-CONFIRM';
    x_Trip_actions_tab(i).shipments_type_flag := 'I';
  END IF;

  IF p_action = 'WT-VOL' THEN
    --
    -- Calculate weight/volume action is
    --  - always allowed for inbound trip
    --  - not allowed for outbound trip, once closed.
    --  - not allowed for mixed closed trip, if called from transactions form
    --
    i := i + 1;
    x_Trip_actions_tab(i).action_not_allowed := 'WT-VOL';
    x_Trip_actions_tab(i).shipments_type_flag := 'O';   -- J-IB-NPARIKH
    x_Trip_actions_tab(i).status_code := 'CL';
    -- J-IB-NPARIKH-{
    i := i + 1;
    x_Trip_actions_tab(i).action_not_allowed := 'WT-VOL';
    x_Trip_actions_tab(i).shipments_type_flag := 'M';
    x_Trip_actions_tab(i).caller := 'WSH_FSTRX';
    x_Trip_actions_tab(i).status_code := 'CL';
    -- J-IB-NPARIKH-}

  END IF;

  IF p_action = 'PICK-RELEASE-UI' THEN
    i := i + 1;
    x_Trip_actions_tab(i).action_not_allowed := 'PICK-RELEASE-UI';
    x_Trip_actions_tab(i).status_code := 'CL';
    i := i + 1;
    x_Trip_actions_tab(i).action_not_allowed := 'PICK-RELEASE-UI';
    x_Trip_actions_tab(i).shipments_type_flag := 'I';

    --HVOP heali
    i := i + 1;
    x_Trip_actions_tab(i).action_not_allowed := 'PICK-RELEASE-UI';
    x_Trip_actions_tab(i).status_code := 'IT';
    --HVOP heali
  END IF;
  IF p_action = 'PICK-RELEASE' THEN
    i := i + 1;
    x_Trip_actions_tab(i).action_not_allowed := 'PICK-RELEASE';
    x_Trip_actions_tab(i).shipments_type_flag := 'I';
    --HVOP heali
    i := i + 1;
    x_Trip_actions_tab(i).action_not_allowed := 'PICK-RELEASE';
    x_Trip_actions_tab(i).status_code := 'IT';
    --HVOP heali
  END IF;
  IF p_action = 'ASSIGN-FREIGHT-COSTS' THEN
    i := i + 1;
    x_Trip_actions_tab(i).action_not_allowed := 'ASSIGN-FREIGHT-COSTS';
    x_Trip_actions_tab(i).shipments_type_flag := 'I';
  END IF;
  IF p_action = 'PRINT-DOC-SET' THEN
    i := i + 1;
    x_Trip_actions_tab(i).action_not_allowed := 'PRINT-DOC-SET';
    x_Trip_actions_tab(i).shipments_type_flag := 'I';
  END IF;

  IF p_action = 'SELECT-CARRIER' THEN

    i := i + 1;
    x_Trip_actions_tab(i).action_not_allowed := 'SELECT-CARRIER';
    x_Trip_actions_tab(i).status_code := 'IT';
    x_Trip_actions_tab(i).message_name := 'WSH_FTE_SEL_TRIP_STATUS';
    i := i + 1;
    x_Trip_actions_tab(i).action_not_allowed := 'SELECT-CARRIER';
    x_Trip_actions_tab(i).status_code := 'CL';
    x_Trip_actions_tab(i).message_name := 'WSH_FTE_SEL_TRIP_STATUS';
    i := i + 1;
    x_Trip_actions_tab(i).action_not_allowed := 'SELECT-CARRIER';
    x_Trip_actions_tab(i).planned_flag := 'Y';
    x_Trip_actions_tab(i).message_name := 'WSH_FTE_SEL_TRIP_PLANNED';
    i := i + 1;
    x_Trip_actions_tab(i).action_not_allowed := 'SELECT-CARRIER';
    x_Trip_actions_tab(i).planned_flag := 'F';
    x_Trip_actions_tab(i).message_name := 'WSH_FTE_SEL_TRIP_PLANNED';
    i := i + 1;
    x_Trip_actions_tab(i).action_not_allowed := 'SELECT-CARRIER';
    x_Trip_actions_tab(i).load_tender_status := 'TENDERED';
    x_Trip_actions_tab(i).message_name := 'WSH_FTE_SEL_TRIP_LT_STATUS';
    i := i + 1;
    x_Trip_actions_tab(i).action_not_allowed := 'SELECT-CARRIER';
    x_Trip_actions_tab(i).load_tender_status := 'ACCEPTED';
    x_Trip_actions_tab(i).message_name := 'WSH_FTE_SEL_TRIP_LT_STATUS';
    i := i + 1;
    x_Trip_actions_tab(i).action_not_allowed := 'SELECT-CARRIER';
    x_Trip_actions_tab(i).load_tender_status := 'AUTO_ACCEPTED';
    x_Trip_actions_tab(i).message_name := 'WSH_FTE_SEL_TRIP_LT_STATUS';

  END IF;

  --OTM R12, glog proj
  IF (l_gc3_is_installed = 'Y') THEN

    -- Disable Include/Ignore actions if OTM is installed
    IF p_action IN ('IGNORE_PLAN', 'INCLUDE_PLAN') THEN
      i := i + 1;
      x_trip_actions_tab(i).action_not_allowed := p_action;
    END IF;

    -- Disable Routing Firm, Routing and Contents Firm, Unfirm for
    -- include for planning trips only
    IF p_action IN ('FIRM', 'PLAN', 'UNPLAN') THEN
      i := i + 1;
      x_trip_actions_tab(i).action_not_allowed  := p_action;
      x_trip_actions_tab(i).ignore_for_planning := 'N';
    END IF;

  END IF;

  -- bug 5837425
  IF p_action IN ('IGNORE_PLAN', 'INCLUDE_PLAN') THEN
    i := i + 1;
    x_trip_actions_tab(i).status_code := 'IT';
    x_trip_actions_tab(i).action_not_allowed := p_action;
    i := i + 1;
    x_trip_actions_tab(i).status_code := 'CL';
    x_trip_actions_tab(i).action_not_allowed := p_action;
  END IF;
  -- bug 5837425

  --
  IF l_debug_on THEN
      WSH_DEBUG_SV.push(l_module_name);
      --
      WSH_DEBUG_SV.log(l_module_name,'p_action', p_action);
  END IF;
  --
  x_return_status :=  WSH_UTIL_CORE.G_RET_STS_SUCCESS;

  IF l_debug_on THEN
      WSH_DEBUG_SV.pop(l_module_name);
  END IF;

EXCEPTION
  -- OTM R12, glog proj
  WHEN OTHERS THEN
    WSH_UTIL_CORE.DEFAULT_HANDLER('WSH_TRIP_VALIDATIONS.init_trip_actions_tbl'
                                        ,l_module_name);
    x_return_status := WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR;
    IF l_debug_on THEN
      WSH_DEBUG_SV.logmsg(l_module_name,'Unexpected error has occured. Oracle error message is '|| SQLERRM,WSH_DEBUG_SV.C_UNEXPEC_ERR_LEVEL);
      WSH_DEBUG_SV.pop(l_module_name,'EXCEPTION:OTHERS');
    END IF;


END Init_Trip_Actions_Tbl;

-- for Load Tender Project
/*
-----------------------------------------------------------------------------
   PROCEDURE  : Get Trip Calc Wtvol
   PARAMETERS : p_tab_id - entity id
                p_entity - entity name -DELIVERY,TRIP,TRIP_STOP,DELIVERY_DETAIL
                p_action_code - action code for each action
                p_phase - 1 for Before the action is performed, 2 for after.
                x_trip_id_tab - Table of Trip ids
                x_return_status - Return Status
  DESCRIPTION : This procedure finds the trip for each entity on the basis
                of p_entity.After the trip is determined, calculate the
                weight/volume for the trip.
------------------------------------------------------------------------------
*/
-- THIS PROCEDURE IS OBSOLETE
PROCEDURE Get_Trip_Calc_Wtvol
  (p_tab_id      IN wsh_util_core.id_tab_type,
   p_entity      IN VARCHAR2,
   p_action_code IN VARCHAR2,
   p_phase       IN NUMBER,
   x_trip_id_tab IN OUT NOCOPY wsh_util_core.id_tab_type,
   x_return_status OUT NOCOPY VARCHAR2
   ) IS

BEGIN

    x_return_status := WSH_UTIL_CORE.G_RET_STS_ERROR;

END get_trip_calc_wtvol;

-- End for Load Tender Project
--
-- J-IB-NPARIKH-{
--
--========================================================================
-- PROCEDURE : Check_close
--
-- PARAMETERS: p_in_rec                Input Record  (Refer to WSHTRVLS.pls for description)
--             x_allowed               Trip can be closed or not
--                                    'Y' : Allowed
--                                    'YW': Allowed with warnings
--                                    'N' : Not Allowed
--                                    'NW': Not Allowed with warnings
--             x_return_status         Return status of API
--
--
-- COMMENT   : This function checks if trip can be closed or not.
--
--             It performs following validations:
--             01. Check if trip has any stops which is not closed. IF so, trip close is not
--                 allowed else it is allowed.
--             02. Check for exceptions logged against trip and its contents
--========================================================================
--
PROCEDURE check_Close
            (
               p_in_rec             IN         ChgStatus_in_rec_type,
               x_return_status      OUT NOCOPY VARCHAR2,
               x_allowed            OUT NOCOPY VARCHAR2
            )
IS
--{
    --
    -- Check if trip has any stop which is not closed yet.
    --
    -- When linked_stop_id is passed, that stop
    -- will also get closed.
    --
    CURSOR any_open_stop (p_trip_id NUMBER,
                          p_stop_id NUMBER,
                          p_linked_stop_id NUMBER) IS
    SELECT stop_id
    FROM   wsh_trip_stops
    WHERE  trip_id      = p_trip_id
    AND    stop_id <> NVL(p_stop_id,-9999)
    AND    stop_id <> NVL(p_linked_stop_id,-9999)
    AND    status_code <> 'CL';
    --
    l_num_warnings          NUMBER;
    l_num_errors            NUMBER;
    l_dummy                 NUMBER;
    --
    -- Exception variables
    l_exceptions_tab  wsh_xc_util.XC_TAB_TYPE;
    l_exp_logged      BOOLEAN := FALSE;
    l_exp_warning     BOOLEAN := FALSE;
    l_msg_count       NUMBER;
    l_msg_data        VARCHAR2(4000);
    l_return_status   VARCHAR2(1);
-- Following three variables are added for BugFix #3947506
    l_out_entity_id     VARCHAR2(100);
    l_out_entity_name   VARCHAR2(100);
    l_out_status        VARCHAR2(100);
    --
    l_debug_on                    BOOLEAN;
    --
    l_module_name        CONSTANT VARCHAR2(100) := 'wsh.plsql.' || g_pkg_name || '.' || 'check_Close';
--}
BEGIN
--{
    --
    l_debug_on := wsh_debug_interface.g_debug;
    --
    IF l_debug_on IS NULL THEN
      l_debug_on := wsh_debug_sv.is_debug_enabled;
    END IF;
    --
    IF l_debug_on THEN
      wsh_debug_sv.push(l_module_name);
      --
      wsh_debug_sv.LOG(l_module_name, 'p_in_rec.trip_id ', p_in_rec.trip_id );
      wsh_debug_sv.LOG(l_module_name, 'p_in_rec.name ', p_in_rec.name );
      wsh_debug_sv.LOG(l_module_name, 'p_in_rec.put_messages', p_in_rec.put_messages);
      wsh_debug_sv.LOG(l_module_name, 'p_in_rec.manual_flag ', p_in_rec.manual_flag );
      wsh_debug_sv.LOG(l_module_name, 'p_in_rec.caller      ', p_in_rec.caller      );
      wsh_debug_sv.LOG(l_module_name, 'p_in_rec.actual_date ', p_in_rec.actual_date );
      wsh_debug_sv.LOG(l_module_name, 'p_in_rec.stop_id ', p_in_rec.stop_id );
      wsh_debug_sv.LOG(l_module_name, 'p_in_rec.linked_stop_id ', p_in_rec.linked_stop_id );
    END IF;
    --
    --
    l_num_warnings  := 0;
    l_num_errors    := 0;
    --
    -- Check if trip has any stops which is not closed. IF so, trip close is not
    -- allowed else it is allowed.
    --
    OPEN any_open_stop(p_in_rec.trip_id, p_in_rec.stop_id, p_in_rec.linked_stop_id);
    FETCH any_open_stop INTO l_dummy;
    --
    IF any_open_stop%FOUND
    THEN
        CLOSE any_open_stop;
        --bug 3410681
        x_allowed       := 'NT';

        RAISE wsh_util_core.e_not_allowed;
    END IF;
    --
    CLOSE any_open_stop;
    --

    -- Check for Exceptions against the Trip
    IF l_debug_on THEN
       WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit WSH_XC_UTIL.Check_Exceptions',WSH_DEBUG_SV.C_PROC_LEVEL);
    END IF;
    l_exceptions_tab.delete;
    l_exp_logged      := FALSE;
    l_exp_warning     := FALSE;
    WSH_XC_UTIL.Check_Exceptions (
                                       p_api_version           => 1.0,
                                       x_return_status         => l_return_status,
                                       x_msg_count             => l_msg_count,
                                       x_msg_data              => l_msg_data,
                                       p_logging_entity_id     => p_in_rec.trip_id,
                                       p_logging_entity_name   => 'TRIP',
                                       p_consider_content      => 'Y',
                                       x_exceptions_tab        => l_exceptions_tab
                                     );
    IF ( l_return_status <>  WSH_UTIL_CORE.G_RET_STS_SUCCESS )  THEN
         x_return_status := l_return_status;
         wsh_util_core.add_message(x_return_status);
         RAISE FND_API.G_EXC_ERROR;
    END IF;
    FOR exp_cnt in 1..l_exceptions_tab.COUNT LOOP
        IF l_exceptions_tab(exp_cnt).exception_behavior = 'ERROR' THEN
           IF l_exceptions_tab(exp_cnt).entity_name = 'TRIP' THEN
              FND_MESSAGE.SET_NAME('WSH','WSH_XC_EXIST_ENTITY');
           ELSE
              FND_MESSAGE.SET_NAME('WSH','WSH_XC_EXIST_CONTENTS');
           END IF;

           -- BugFix #3947506
           WSH_UTIL_CORE.Get_Entity_Name
                ( l_exceptions_tab(exp_cnt).entity_id,
                  l_exceptions_tab(exp_cnt).entity_name,
                  l_out_entity_id,
                  l_out_entity_name,
                  l_out_status);

          IF ( l_out_status <>  WSH_UTIL_CORE.G_RET_STS_SUCCESS )  THEN
                  wsh_util_core.add_message(l_out_status);
                  RAISE FND_API.G_EXC_ERROR;
          END IF;
           -- End of code BugFix #3947506

           FND_MESSAGE.SET_TOKEN('ENTITY_NAME',l_out_entity_name);  -- BugFix #3947506
           FND_MESSAGE.SET_TOKEN('ENTITY_ID',l_out_entity_id);  -- BugFix #3947506
           FND_MESSAGE.SET_TOKEN('EXCEPTION_BEHAVIOR','Error');
           x_return_status := WSH_UTIL_CORE.G_RET_STS_ERROR;
           wsh_util_core.add_message(x_return_status);
           l_num_warnings := l_num_warnings + 1;

           --bug 3410681
           x_allowed       := 'N';
           l_out_entity_id := '';  -- BugFix #3947506
           l_out_entity_name := '';  -- BugFix #3947506

           RAISE wsh_util_core.e_not_allowed;
        ELSIF l_exceptions_tab(exp_cnt).exception_behavior = 'WARNING' THEN
           IF l_exceptions_tab(exp_cnt).entity_name = 'TRIP' THEN
              FND_MESSAGE.SET_NAME('WSH','WSH_XC_EXIST_ENTITY');
              FND_MESSAGE.SET_TOKEN('ENTITY_NAME','Trip');
              FND_MESSAGE.SET_TOKEN('ENTITY_ID',wsh_trips_pvt.get_name(l_exceptions_tab(exp_cnt).entity_id));
              FND_MESSAGE.SET_TOKEN('EXCEPTION_BEHAVIOR','Warning');
              x_return_status :=  WSH_UTIL_CORE.G_RET_STS_WARNING;
              wsh_util_core.add_message(x_return_status);
              l_num_warnings := l_num_warnings + 1;
              l_exp_warning  := TRUE;
           ELSIF NOT (l_exp_logged) THEN
              -- BugFix #3947506
              WSH_UTIL_CORE.Get_Entity_Name
                ( l_exceptions_tab(exp_cnt).entity_id,
                  l_exceptions_tab(exp_cnt).entity_name,
                  l_out_entity_id,
                  l_out_entity_name,
                  l_out_status);

              IF ( l_out_status <>  WSH_UTIL_CORE.G_RET_STS_SUCCESS )  THEN
                  wsh_util_core.add_message(l_out_status);
                  RAISE FND_API.G_EXC_ERROR;
              END IF;
           -- End of code BugFix #3947506
              FND_MESSAGE.SET_NAME('WSH','WSH_XC_EXIST_CONTENTS');
              FND_MESSAGE.SET_TOKEN('ENTITY_NAME',l_out_entity_name); -- BugFix #3947506
              FND_MESSAGE.SET_TOKEN('ENTITY_ID',l_out_entity_id); -- BugFix #3947506
              FND_MESSAGE.SET_TOKEN('EXCEPTION_BEHAVIOR','Warning');
              x_return_status :=  WSH_UTIL_CORE.G_RET_STS_WARNING;
              l_exp_logged := TRUE;
              wsh_util_core.add_message(x_return_status);
              l_num_warnings := l_num_warnings + 1;
              l_exp_warning  := TRUE;
              l_out_entity_id := '';  -- BugFix #3947506
              l_out_entity_name := '';  -- BugFix #3947506
           END IF;
        END IF;
    END LOOP;
    --

    IF l_num_errors > 0
    THEN
        x_return_status         := WSH_UTIL_CORE.G_RET_STS_ERROR;
        x_allowed               := 'N';
    ELSIF l_num_warnings > 0
    THEN
        x_return_status := WSH_UTIL_CORE.G_RET_STS_WARNING;
    ELSE
        x_return_status := WSH_UTIL_CORE.G_RET_STS_SUCCESS;
    END IF;
    --
    -- If Exceptions have warnings, then display warnings but allow to proceed
    IF l_exp_warning THEN
       x_allowed := 'YW';
    ELSE
       x_allowed := 'Y';
    END IF;
    --
    -- Debug Statements
    --
    IF l_debug_on THEN
        WSH_DEBUG_SV.pop(l_module_name);
    END IF;
    --
--}
EXCEPTION
--{
    WHEN wsh_util_core.e_not_allowed THEN
      IF l_num_warnings > 0
      THEN
          x_return_status := WSH_UTIL_CORE.G_RET_STS_WARNING;
      ELSE
          x_return_status := WSH_UTIL_CORE.G_RET_STS_SUCCESS;
      END IF;
      --
      --
      --
      IF l_debug_on THEN
        WSH_DEBUG_SV.logmsg(l_module_name,'e_not_allowed exception has occured ',WSH_DEBUG_SV.C_EXCEP_LEVEL);
        WSH_DEBUG_SV.pop(l_module_name,'EXCEPTION:e_not_allowed');
      END IF;
      --
    WHEN wsh_util_core.e_not_allowed_warning THEN
      IF l_num_warnings > 0
      THEN
          x_return_status := WSH_UTIL_CORE.G_RET_STS_WARNING;
      ELSE
          x_return_status := WSH_UTIL_CORE.G_RET_STS_SUCCESS;
      END IF;
      --
      x_allowed := 'NW';
      --
      --
      IF l_debug_on THEN
        WSH_DEBUG_SV.logmsg(l_module_name,'e_not_allowed_warning exception has occured ',WSH_DEBUG_SV.C_EXCEP_LEVEL);
        WSH_DEBUG_SV.pop(l_module_name,'EXCEPTION:e_not_allowed_warning');
      END IF;
      --
    WHEN FND_API.G_EXC_ERROR THEN

      x_return_status := WSH_UTIL_CORE.G_RET_STS_ERROR;
      --
      IF l_debug_on THEN
        WSH_DEBUG_SV.logmsg(l_module_name,'FND_API.G_EXC_ERROR exception has occured ',WSH_DEBUG_SV.C_EXCEP_LEVEL);
        WSH_DEBUG_SV.pop(l_module_name,'EXCEPTION:FND_API.G_EXC_ERROR');
      END IF;
      --
    WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN

      x_return_status := WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR ;
      --
      IF l_debug_on THEN
        WSH_DEBUG_SV.logmsg(l_module_name,'Unexpected error has occured. Oracle error message is '|| SQLERRM,WSH_DEBUG_SV.C_UNEXPEC_ERR_LEVEL);
        WSH_DEBUG_SV.pop(l_module_name,'EXCEPTION:FND_API.G_EXC_UNEXPECTED_ERROR');
      END IF;
      --
    WHEN WSH_UTIL_CORE.G_EXC_WARNING THEN
      x_return_status := WSH_UTIL_CORE.G_RET_STS_WARNING;
      --
      IF l_debug_on THEN
        WSH_DEBUG_SV.logmsg(l_module_name,'WSH_UTIL_CORE.G_EXC_WARNING exception has occured ',WSH_DEBUG_SV.C_EXCEP_LEVEL);
        WSH_DEBUG_SV.pop(l_module_name,'EXCEPTION:WSH_UTIL_CORE.G_EXC_WARNING');
      END IF;
      --
    WHEN OTHERS THEN

      x_return_status := WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR ;
      wsh_util_core.default_handler('WSH_TRIP_VALIDATIONS.check_Close',l_module_name);
      --
      IF l_debug_on THEN
        WSH_DEBUG_SV.pop(l_module_name,'EXCEPTION:OTHERS');
      END IF;
      --
--}
END check_Close;
--
--
--========================================================================
-- PROCEDURE : check_inTransit
--
-- PARAMETERS: p_in_rec                Input Record  (Refer to WSHTRVLS.pls for description)
--             x_allowed               Trip can be closed or not
--                                    'Y' : Allowed
--                                    'YW': Allowed with warnings
--                                    'N' : Not Allowed
--                                    'NW': Not Allowed with warnings
--             x_return_status         Return status of API
--
--
-- COMMENT   : This function checks if trip can be set to in-transit or not.
--
--             It performs following validations:
--             01. Check if trip has any stops which is closed. IF so, trip can be
--                 set to in-transit else not. This check is done ONLY when
--                 it is being called with Stop_Id as NULL
--             02. Check for exceptions logged against trip and its contents
--========================================================================
--
PROCEDURE check_inTransit
            (
               p_in_rec             IN         ChgStatus_in_rec_type,
               x_return_status      OUT NOCOPY VARCHAR2,
               x_allowed            OUT NOCOPY VARCHAR2
            )
IS
--{
    --
    -- Check if trip has any closed stop
    --
    CURSOR any_closed_stop (p_trip_id NUMBER) IS
    SELECT stop_id
    FROM   wsh_trip_stops
    WHERE  trip_id      = p_trip_id
    AND    status_code  = 'CL';
    --
    l_num_warnings          NUMBER;
    l_num_errors            NUMBER;
    l_dummy                 NUMBER;
    --
    -- Exception variables
    l_exceptions_tab  wsh_xc_util.XC_TAB_TYPE;
    l_exp_logged      BOOLEAN := FALSE;
    l_exp_warning     BOOLEAN := FALSE;
    l_msg_count       NUMBER;
    l_msg_data        VARCHAR2(4000);
    l_return_status   VARCHAR2(1);
-- Following three variables are added for BugFix #3947506
    l_out_entity_id     VARCHAR2(100);
    l_out_entity_name   VARCHAR2(100);
    l_out_status        VARCHAR2(1);
    --
    l_debug_on                    BOOLEAN;
    --
    l_module_name        CONSTANT VARCHAR2(100) := 'wsh.plsql.' || g_pkg_name || '.' || 'check_inTransit';
--}
BEGIN
--{
    --
    l_debug_on := wsh_debug_interface.g_debug;
    --
    IF l_debug_on IS NULL THEN
      l_debug_on := wsh_debug_sv.is_debug_enabled;
    END IF;
    --
    IF l_debug_on THEN
      wsh_debug_sv.push(l_module_name);
      --
      wsh_debug_sv.LOG(l_module_name, 'p_in_rec.trip_id ', p_in_rec.trip_id );
      wsh_debug_sv.LOG(l_module_name, 'p_in_rec.name ', p_in_rec.name );
      wsh_debug_sv.LOG(l_module_name, 'p_in_rec.put_messages', p_in_rec.put_messages);
      wsh_debug_sv.LOG(l_module_name, 'p_in_rec.manual_flag ', p_in_rec.manual_flag );
      wsh_debug_sv.LOG(l_module_name, 'p_in_rec.caller      ', p_in_rec.caller      );
      wsh_debug_sv.LOG(l_module_name, 'p_in_rec.actual_date ', p_in_rec.actual_date );
      wsh_debug_sv.LOG(l_module_name, 'p_in_rec.stop_id ', p_in_rec.stop_id );
    END IF;
    --
    --
    l_num_warnings  := 0;
    l_num_errors    := 0;
    --
    --
    -- Stop_id is not null only when called from WSH_TRIP_STOP_VALIDATIONS.Check_Stop_Close api
    -- Otherwise it should be null when called from other APIs
    -- This check is required due to inbound logistics changes, trip needs to be set in-transit
    -- when any stop of trip is closed
    IF p_in_rec.stop_id IS NULL THEN
       OPEN any_closed_stop(p_in_rec.trip_id);
       FETCH any_closed_stop INTO l_dummy;
       --
       -- Check if trip has any stops which is closed. IF so, trip can be
       -- set to in-transit else not.
       --
       IF any_closed_stop%NOTFOUND
       THEN
           CLOSE any_closed_stop;
           RAISE wsh_util_core.e_not_allowed;
       END IF;
       --
       CLOSE any_closed_stop;
    END IF;
    --

    -- Check for Exceptions against the Trip
    IF l_debug_on THEN
       WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit WSH_XC_UTIL.Check_Exceptions',WSH_DEBUG_SV.C_PROC_LEVEL);
    END IF;
    l_exceptions_tab.delete;
    l_exp_logged      := FALSE;
    l_exp_warning     := FALSE;
    WSH_XC_UTIL.Check_Exceptions (
                                       p_api_version           => 1.0,
                                       x_return_status         => l_return_status,
                                       x_msg_count             => l_msg_count,
                                       x_msg_data              => l_msg_data,
                                       p_logging_entity_id     => p_in_rec.trip_id,
                                       p_logging_entity_name   => 'TRIP',
                                       p_consider_content      => 'Y',
                                       x_exceptions_tab        => l_exceptions_tab
                                     );
    IF ( l_return_status <>  WSH_UTIL_CORE.G_RET_STS_SUCCESS )  THEN
         x_return_status := l_return_status;
         wsh_util_core.add_message(x_return_status);
         RAISE FND_API.G_EXC_ERROR;
    END IF;
    FOR exp_cnt in 1..l_exceptions_tab.COUNT LOOP
        IF l_exceptions_tab(exp_cnt).exception_behavior = 'ERROR' THEN
           IF l_exceptions_tab(exp_cnt).entity_name = 'TRIP' THEN
              FND_MESSAGE.SET_NAME('WSH','WSH_XC_EXIST_ENTITY');
           ELSE
              FND_MESSAGE.SET_NAME('WSH','WSH_XC_EXIST_CONTENTS');
           END IF;

           -- BugFix #3947506
           WSH_UTIL_CORE.Get_Entity_Name
                ( l_exceptions_tab(exp_cnt).entity_id,
                  l_exceptions_tab(exp_cnt).entity_name,
                  l_out_entity_id,
                  l_out_entity_name,
                  l_out_status);

           IF ( l_out_status <>  WSH_UTIL_CORE.G_RET_STS_SUCCESS )  THEN
                wsh_util_core.add_message(l_out_status);
                RAISE FND_API.G_EXC_ERROR;
           END IF;
           -- End of code BugFix #3947506

           FND_MESSAGE.SET_TOKEN('ENTITY_NAME',l_out_entity_name); -- BugFix #3947506
           FND_MESSAGE.SET_TOKEN('ENTITY_ID',l_out_entity_id); -- BugFix #3947506
           FND_MESSAGE.SET_TOKEN('EXCEPTION_BEHAVIOR','Error');
           x_return_status := WSH_UTIL_CORE.G_RET_STS_ERROR;
           wsh_util_core.add_message(x_return_status);
           l_num_warnings := l_num_warnings + 1;
           RAISE wsh_util_core.e_not_allowed;
        ELSIF l_exceptions_tab(exp_cnt).exception_behavior = 'WARNING' THEN
           IF l_exceptions_tab(exp_cnt).entity_name = 'TRIP' THEN
              FND_MESSAGE.SET_NAME('WSH','WSH_XC_EXIST_ENTITY');
              FND_MESSAGE.SET_TOKEN('ENTITY_NAME','Trip');
              FND_MESSAGE.SET_TOKEN('ENTITY_ID',wsh_trips_pvt.get_name(l_exceptions_tab(exp_cnt).entity_id));
              FND_MESSAGE.SET_TOKEN('EXCEPTION_BEHAVIOR','Warning');
              x_return_status :=  WSH_UTIL_CORE.G_RET_STS_WARNING;
              wsh_util_core.add_message(x_return_status);
              l_num_warnings := l_num_warnings + 1;
              l_exp_warning  := TRUE;
           ELSIF NOT (l_exp_logged) THEN
              -- BugFix #3947506
              WSH_UTIL_CORE.Get_Entity_Name
                ( l_exceptions_tab(exp_cnt).entity_id,
                  l_exceptions_tab(exp_cnt).entity_name,
                  l_out_entity_id,
                  l_out_entity_name,
                  l_out_status);

              IF ( l_out_status <>  WSH_UTIL_CORE.G_RET_STS_SUCCESS )  THEN
                wsh_util_core.add_message(l_out_status);
                RAISE FND_API.G_EXC_ERROR;
              END IF;
              -- End of code BugFix #3947506

              FND_MESSAGE.SET_NAME('WSH','WSH_XC_EXIST_CONTENTS');
              FND_MESSAGE.SET_TOKEN('ENTITY_NAME',l_out_entity_name); -- BugFix #3947506
              FND_MESSAGE.SET_TOKEN('ENTITY_ID',l_out_entity_id); -- BugFix #3947506
              FND_MESSAGE.SET_TOKEN('EXCEPTION_BEHAVIOR','Warning');
              x_return_status :=  WSH_UTIL_CORE.G_RET_STS_WARNING;
              l_exp_logged := TRUE;
              wsh_util_core.add_message(x_return_status);
              l_num_warnings := l_num_warnings + 1;
              l_exp_warning  := TRUE;
           END IF;
        END IF;
    END LOOP;
    --

    IF l_num_errors > 0
    THEN
        x_return_status         := WSH_UTIL_CORE.G_RET_STS_ERROR;
        x_allowed               := 'N';
    ELSIF l_num_warnings > 0
    THEN
        x_return_status := WSH_UTIL_CORE.G_RET_STS_WARNING;
    ELSE
        x_return_status := WSH_UTIL_CORE.G_RET_STS_SUCCESS;
    END IF;
    --
    --
    -- If Exceptions have warnings, then display warnings but allow to proceed
    IF l_exp_warning THEN
       x_allowed := 'YW';
    ELSE
       x_allowed := 'Y';
    END IF;
    --
    -- Debug Statements
    --
    IF l_debug_on THEN
        WSH_DEBUG_SV.pop(l_module_name);
    END IF;
    --
--}
EXCEPTION
--{
    WHEN wsh_util_core.e_not_allowed THEN
      IF l_num_warnings > 0
      THEN
          x_return_status := WSH_UTIL_CORE.G_RET_STS_WARNING;
      ELSE
          x_return_status := WSH_UTIL_CORE.G_RET_STS_SUCCESS;
      END IF;
      --
      x_allowed       := 'N';
      --
      --
      IF l_debug_on THEN
        WSH_DEBUG_SV.logmsg(l_module_name,'e_not_allowed exception has occured ',WSH_DEBUG_SV.C_EXCEP_LEVEL);
        WSH_DEBUG_SV.pop(l_module_name,'EXCEPTION:e_not_allowed');
      END IF;
      --
    WHEN wsh_util_core.e_not_allowed_warning THEN
      IF l_num_warnings > 0
      THEN
          x_return_status := WSH_UTIL_CORE.G_RET_STS_WARNING;
      ELSE
          x_return_status := WSH_UTIL_CORE.G_RET_STS_SUCCESS;
      END IF;
      --
      x_allowed := 'NW';
      --
      --
      IF l_debug_on THEN
        WSH_DEBUG_SV.logmsg(l_module_name,'e_not_allowed_warning exception has occured ',WSH_DEBUG_SV.C_EXCEP_LEVEL);
        WSH_DEBUG_SV.pop(l_module_name,'EXCEPTION:e_not_allowed_warning');
      END IF;
      --
    WHEN FND_API.G_EXC_ERROR THEN

      x_return_status := WSH_UTIL_CORE.G_RET_STS_ERROR;
      --
      IF l_debug_on THEN
        WSH_DEBUG_SV.logmsg(l_module_name,'FND_API.G_EXC_ERROR exception has occured ',WSH_DEBUG_SV.C_EXCEP_LEVEL);
        WSH_DEBUG_SV.pop(l_module_name,'EXCEPTION:FND_API.G_EXC_ERROR');
      END IF;
      --
    WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN

      x_return_status := WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR ;
      --
      IF l_debug_on THEN
        WSH_DEBUG_SV.logmsg(l_module_name,'Unexpected error has occured. Oracle error message is '|| SQLERRM,WSH_DEBUG_SV.C_UNEXPEC_ERR_LEVEL);
        WSH_DEBUG_SV.pop(l_module_name,'EXCEPTION:FND_API.G_EXC_UNEXPECTED_ERROR');
      END IF;
      --
    WHEN WSH_UTIL_CORE.G_EXC_WARNING THEN
      x_return_status := WSH_UTIL_CORE.G_RET_STS_WARNING;
      --
      IF l_debug_on THEN
        WSH_DEBUG_SV.logmsg(l_module_name,'WSH_UTIL_CORE.G_EXC_WARNING exception has occured ',WSH_DEBUG_SV.C_EXCEP_LEVEL);
        WSH_DEBUG_SV.pop(l_module_name,'EXCEPTION:WSH_UTIL_CORE.G_EXC_WARNING');
      END IF;
      --
    WHEN OTHERS THEN

      x_return_status := WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR ;
      wsh_util_core.default_handler('WSH_TRIP_VALIDATIONS.check_inTransit',l_module_name);
      --
      IF l_debug_on THEN
        WSH_DEBUG_SV.pop(l_module_name,'EXCEPTION:OTHERS');
      END IF;
      --
--}
END check_inTransit;
--
--
--========================================================================
-- PROCEDURE : Validate_Trip_status
--
-- PARAMETERS: p_trip_id               Trip ID
--             p_action                Action (Not used)
--             x_return_status         Return status of API
--
--
-- COMMENT   : This API is called by delivery group API while assigning delivery to trip
--
--             It performs following validations:
--             01. IF trip is routing and content firm or trip is in-transit/closed, delivery
--                 cannot be assigned to the trip
--========================================================================
--
--
PROCEDURE Validate_Trip_status
    (
      p_trip_id       IN            NUMBER,
      p_action        IN            VARCHAR2,
      x_return_status OUT NOCOPY    VARCHAR2
    )
IS
--{
    /* J TP Release : If assigning del to trip doesn't introduce new stops, ok to assign to planned trips */

    CURSOR trip_csr (p_trip_id NUMBER)
    IS
      select status_code, name, nvl(planned_flag,'N') planned_flag
      from wsh_trips
      where trip_id = p_trip_id;
    --
    l_trip_rec trip_csr%ROWTYPE;
    --
    l_debug_on BOOLEAN;
    l_module_name CONSTANT VARCHAR2(100) := 'wsh.plsql.' || G_PKG_NAME || '.' || 'VALIDATE_TRIP_STATUS';
--}
BEGIN
--{
    --
    l_debug_on := WSH_DEBUG_INTERFACE.g_debug;
    --
    IF l_debug_on IS NULL
    THEN
        l_debug_on := WSH_DEBUG_SV.is_debug_enabled;
    END IF;
    --
    IF l_debug_on THEN
        WSH_DEBUG_SV.push(l_module_name);
        WSH_DEBUG_SV.log(l_module_name,'p_trip_id',p_trip_id);
        WSH_DEBUG_SV.log(l_module_name,'p_action',p_action);
    END IF;
    --
    x_return_status := WSH_UTIL_CORE.G_RET_STS_SUCCESS;
    --
    IF (p_trip_id IS NOT NULL)
    THEN
    --{
        OPEN trip_csr(p_trip_id);
        FETCH trip_csr INTO l_trip_rec;
        CLOSE trip_csr;
        --
        IF l_trip_rec.planned_flag NOT IN ('N','Y')
        THEN
            -- Trip is routing and content firm.
            RAISE wsh_util_core.e_not_allowed;
        END IF;
        --
        IF  l_trip_rec.status_code IN ('IT','CL')
        THEN
            RAISE wsh_util_core.e_not_allowed;
        END IF;
        --
    --}
    END IF;
    --
    IF l_debug_on THEN
        WSH_DEBUG_SV.pop(l_module_name);
    END IF;
--}
EXCEPTION
--{
    WHEN wsh_util_core.e_not_allowed THEN
        x_return_status := WSH_UTIL_CORE.G_RET_STS_ERROR;
        FND_MESSAGE.SET_NAME('WSH','WSH_TRIP_STATUS_NO_ACTION');
        FND_MESSAGE.SET_TOKEN('TRIP_NAME', l_trip_rec.name);
        wsh_util_core.add_message(WSH_UTIL_CORE.G_RET_STS_ERROR,l_module_name);
        --
        IF l_debug_on THEN
            WSH_DEBUG_SV.logmsg(l_module_name,'e_not_allowed exception has occured ',WSH_DEBUG_SV.C_EXCEP_LEVEL);
            WSH_DEBUG_SV.pop(l_module_name,'EXCEPTION:e_not_allowed');
        END IF;
        --
    WHEN OTHERS THEN
        x_return_status := WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR ;
        wsh_util_core.default_handler('WSH_TRIP_VALIDATIONS.validate_trip_status', l_module_name);
        IF l_debug_on THEN
           WSH_DEBUG_SV.pop(l_module_name,'EXCEPTION:OTHERS');
        END IF;
--}
END validate_trip_status;
--
--
--
--========================================================================
-- FUNCTION : has_outbound_deliveries
--
-- PARAMETERS: p_trip_id         Trip ID
--             p_stop_id         Stop ID (Optional)
--             Returns           'Y' if trip/stop has outbound deliveries
--             Returns           'N' if trip/stop does not have  outbound deliveries
--
--
-- COMMENT   : This function determines if trip/stop has outbound (O/IO) deliveries
--             associated with it.
--
--             If stop is passed, it checks if any outbound(O/IO) delivery is being
--             picked up or dropped off at the stop. If so, it returns 'Y' else 'N'
--
--             If stop is not passed, it checks if any outbound(O/IO) delivery is being
--             picked up or dropped off at any stop of the trip.
--             If so, it returns 'Y' else 'N'
--
--             If trip id is not passed in, it returns 'N'
--             If invalid trip/stop id is passed in, it returns 'N'
--========================================================================
--
FUNCTION has_outbound_deliveries
    (
      p_trip_id       IN            NUMBER,
      p_stop_id       IN            NUMBER DEFAULT NULL
    )
RETURN VARCHAR2
IS
--{
    --
    -- Look for outbound (O/IO) deliveries being picked up or dropped off at stop/trip.
    --
    CURSOR trip_csr (p_trip_id NUMBER, p_stop_id NUMBER)
    IS
      SELECT 1
      FROM   wsh_delivery_legs wdl,
             wsh_new_deliveries wnd,
             wsh_trip_stops wts
      WHERE  wts.trip_id                      = p_trip_id
      AND    wdl.delivery_id                  = wnd.delivery_id
      AND    NVL(wnd.shipment_direction,'O') IN ( 'O','IO' )
      AND    ( p_stop_id is null  or wts.stop_id = p_stop_id ) --Bugfix 3639920
      AND    (
                    wdl.pick_up_stop_id  = wts.stop_id
                OR  wdl.drop_off_stop_id = wts.stop_id
             );
    --
    l_cnt      NUMBER := 0;
    --
    l_debug_on BOOLEAN;
    l_module_name CONSTANT VARCHAR2(100) := 'wsh.plsql.' || G_PKG_NAME || '.' || 'has_outbound_deliveries';
--}
BEGIN
--{
    --
    l_debug_on := WSH_DEBUG_INTERFACE.g_debug;
    --
    IF l_debug_on IS NULL
    THEN
        l_debug_on := WSH_DEBUG_SV.is_debug_enabled;
    END IF;
    --
    IF l_debug_on THEN
        WSH_DEBUG_SV.push(l_module_name);
        WSH_DEBUG_SV.log(l_module_name,'p_trip_id',p_trip_id);
        WSH_DEBUG_SV.log(l_module_name,'p_stop_id',p_stop_id);
    END IF;
    --
    --
    l_cnt := 0;
    --
    IF (p_trip_id IS NOT NULL)
    THEN
    --{
        OPEN trip_csr(p_trip_id, p_stop_id);
        FETCH trip_csr INTO l_cnt;
        CLOSE trip_csr;
    --}
    END IF;
    --
    --
    IF l_debug_on THEN
        WSH_DEBUG_SV.log(l_module_name,'l_cnt',l_cnt);
        WSH_DEBUG_SV.pop(l_module_name);
    END IF;
    --
    IF l_cnt = 1
    THEN
        RETURN('Y');
    ELSE
        RETURN('N');
    END IF;
--}
EXCEPTION
--{
    WHEN OTHERS THEN
        wsh_util_core.default_handler('WSH_TRIP_VALIDATIONS.has_outbound_deliveries', l_module_name);
        --
        IF l_debug_on THEN
           WSH_DEBUG_SV.pop(l_module_name,'EXCEPTION:OTHERS');
        END IF;
        --
        RAISE;
--}
END has_outbound_deliveries;
--
--
--
--========================================================================
-- FUNCTION : has_inbound_deliveries
--
-- PARAMETERS: p_trip_id         Trip ID
--             p_stop_id         Stop ID (Optional)
--             Returns           'Y' if trip/stop has inbound deliveries
--             Returns           'N' if trip/stop does not have  inbound deliveries
--
--
-- COMMENT   : This function determines if trip/stop has inbound (not O/IO) deliveries
--             associated with it.
--
--             If stop is passed, it checks if any inbound(not O/IO) delivery is being
--             picked up or dropped off at the stop. If so, it returns 'Y' else 'N'
--
--             If stop is not passed, it checks if any inbound(not O/IO) delivery is being
--             picked up or dropped off at any stop of the trip.
--             If so, it returns 'Y' else 'N'
--
--             If trip id is not passed in, it returns 'N'
--             If invalid trip/stop id is passed in, it returns 'N'
--========================================================================
--
FUNCTION has_inbound_deliveries
    (
      p_trip_id       IN            NUMBER,
      p_stop_id       IN            NUMBER DEFAULT NULL
    )
RETURN VARCHAR2
IS
--{
    --
    -- Look for inbound (not O/IO) deliveries being picked up or dropped off at stop/trip.
    --
    CURSOR trip_csr (p_trip_id NUMBER, p_stop_id NUMBER)
    IS
      SELECT 1
      FROM   wsh_delivery_legs wdl,
             wsh_new_deliveries wnd,
             wsh_trip_stops wts
      WHERE  wts.trip_id                      = p_trip_id
      AND    wdl.delivery_id                  = wnd.delivery_id
      AND    NVL(wnd.shipment_direction,'O') NOT IN ( 'O','IO' )
      AND    ( p_stop_id is null  or wts.stop_id = p_stop_id )  --Bugfix 3639920
      AND    (
                    wdl.pick_up_stop_id  = wts.stop_id
                OR  wdl.drop_off_stop_id = wts.stop_id
             );
    --
    l_cnt      NUMBER := 0;
    --
    l_debug_on BOOLEAN;
    l_module_name CONSTANT VARCHAR2(100) := 'wsh.plsql.' || G_PKG_NAME || '.' || 'has_inbound_deliveries';
--}
BEGIN
--{
    --
    l_debug_on := WSH_DEBUG_INTERFACE.g_debug;
    --
    IF l_debug_on IS NULL
    THEN
        l_debug_on := WSH_DEBUG_SV.is_debug_enabled;
    END IF;
    --
    IF l_debug_on THEN
        WSH_DEBUG_SV.push(l_module_name);
        WSH_DEBUG_SV.log(l_module_name,'p_trip_id',p_trip_id);
        WSH_DEBUG_SV.log(l_module_name,'p_stop_id',p_stop_id);
    END IF;
    --
    --
    l_cnt := 0;
    --
    IF (p_trip_id IS NOT NULL)
    THEN
    --{
        OPEN trip_csr(p_trip_id, p_stop_id);
        FETCH trip_csr INTO l_cnt;
        CLOSE trip_csr;
    --}
    END IF;
    --
    IF l_debug_on THEN
        WSH_DEBUG_SV.log(l_module_name,'l_cnt',l_cnt);
        WSH_DEBUG_SV.pop(l_module_name);
    END IF;
    --
    IF l_cnt = 1
    THEN
        RETURN('Y');
    ELSE
        RETURN('N');
    END IF;
    --
--}
EXCEPTION
--{
    WHEN OTHERS THEN
        wsh_util_core.default_handler('WSH_TRIP_VALIDATIONS.has_inbound_deliveries', l_module_name);
        --
        IF l_debug_on THEN
           WSH_DEBUG_SV.pop(l_module_name,'EXCEPTION:OTHERS');
        END IF;
        --
        RAISE;
--}
END has_inbound_deliveries;
--
--
--
--========================================================================
-- FUNCTION : has_mixed_deliveries
--
-- PARAMETERS: p_trip_id         Trip ID
--             p_stop_id         Stop ID (Optional)
--             Returns           'Y' if trip/stop has mixed deliveries
--             Returns           'N' if trip/stop does not have  mixed deliveries
--
--
-- COMMENT   : This function determines if trip/stop has mixed (both inbound and outbound)
--             deliveries associated with it.
--
--             Following is the logic:
--             01. Call has_outbound_deliveries
--             02. Call has_inbound_deliveries
--             03. Set return values as follows, using outcome of steps above.
--
--                 Has Outbound  Has Inbound     Return Value(Meaning)
--                      Y            Y            Y
--                      Y            N            NO (No,has only outbound)
--                      N            Y            NI (No,has only inbound)
--                      N            N            N  (No,no deliveries)
--
--             If trip id is not passed in, it returns 'N'
--             If invalid trip/stop id is passed in, it returns 'N'
--========================================================================
--
FUNCTION has_mixed_deliveries
    (
      p_trip_id       IN            NUMBER,
      p_stop_id       IN            NUMBER DEFAULT NULL
    )
RETURN VARCHAR2
IS
--{
    l_has_outbound_deliveries VARCHAR2(10);
    l_has_inbound_deliveries  VARCHAR2(10);
    l_has_mixed_deliveries    VARCHAR2(10);
    --
    l_debug_on BOOLEAN;
    l_module_name CONSTANT VARCHAR2(100) := 'wsh.plsql.' || G_PKG_NAME || '.' || 'has_mixed_deliveries';
--}
BEGIN
--{
    --
    l_debug_on := WSH_DEBUG_INTERFACE.g_debug;
    --
    IF l_debug_on IS NULL
    THEN
        l_debug_on := WSH_DEBUG_SV.is_debug_enabled;
    END IF;
    --
    IF l_debug_on THEN
        WSH_DEBUG_SV.push(l_module_name);
        WSH_DEBUG_SV.log(l_module_name,'p_trip_id',p_trip_id);
        WSH_DEBUG_SV.log(l_module_name,'p_stop_id',p_stop_id);
    END IF;
    --
    --
    l_has_mixed_deliveries := 'N';
    --
    IF (p_trip_id IS NOT NULL)
    THEN
    --{
        IF l_debug_on THEN
            WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit WSH_TRIP_VALIDATIONS.has_outbound_deliveries',WSH_DEBUG_SV.C_PROC_LEVEL);
        END IF;
        --
        --
        l_has_outbound_deliveries := WSH_TRIP_VALIDATIONS.has_outbound_deliveries
                                        (
                                          p_trip_id => p_trip_id,
                                          p_stop_id => p_stop_id
                                        );
        --
        --
        IF l_debug_on THEN
            WSH_DEBUG_SV.log(l_module_name,'l_has_outbound_deliveries',l_has_outbound_deliveries);
            WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit WSH_TRIP_VALIDATIONS.has_inbound_deliveries',WSH_DEBUG_SV.C_PROC_LEVEL);
        END IF;
        --
        l_has_inbound_deliveries  := WSH_TRIP_VALIDATIONS.has_inbound_deliveries
                                        (
                                          p_trip_id => p_trip_id,
                                          p_stop_id => p_stop_id
                                        );
        --
        IF  l_has_outbound_deliveries = 'Y'
        AND l_has_inbound_deliveries  = 'Y'
        THEN
            l_has_mixed_deliveries := 'Y';
        ELSIF  l_has_outbound_deliveries = 'Y'
        AND l_has_inbound_deliveries  = 'N'
        THEN
            l_has_mixed_deliveries := 'NO';
        ELSIF  l_has_outbound_deliveries = 'N'
        AND l_has_inbound_deliveries  = 'Y'
        THEN
            l_has_mixed_deliveries := 'NI';
        END IF;
    --}
    END IF;
    --
    --
    IF l_debug_on THEN
        WSH_DEBUG_SV.log(l_module_name,'l_has_inbound_deliveries',l_has_inbound_deliveries);
        WSH_DEBUG_SV.log(l_module_name,'l_has_mixed_deliveries',l_has_mixed_deliveries);
        WSH_DEBUG_SV.pop(l_module_name);
    END IF;
    --
    RETURN(l_has_mixed_deliveries);
--}
EXCEPTION
--{
    WHEN OTHERS THEN
        wsh_util_core.default_handler('WSH_TRIP_VALIDATIONS.has_mixed_deliveries', l_module_name);
        --
        IF l_debug_on THEN
           WSH_DEBUG_SV.pop(l_module_name,'EXCEPTION:OTHERS');
        END IF;
        --
        RAISE;
--}
END has_mixed_deliveries;
--
-- J-IB-NPARIKH-}
--
--3509004:public api change
PROCEDURE   user_non_updatable_columns
     (p_user_in_rec     IN WSH_TRIPS_PVT.trip_rec_type,
      p_out_rec         IN WSH_TRIPS_PVT.trip_rec_type,
      p_in_rec          IN WSH_TRIPS_GRP.TripInRecType,
      x_return_status   OUT NOCOPY    VARCHAR2)

IS
l_attributes VARCHAR2(2500) ;
k         number;
l_return_status VARCHAR2(1);
l_debug_on BOOLEAN;
l_module_name CONSTANT VARCHAR2(100) := 'wsh.plsql.' || G_PKG_NAME || '.' || 'user_non_updatable_columns';

BEGIN

  l_debug_on := WSH_DEBUG_INTERFACE.g_debug;
  --
  IF l_debug_on IS NULL
  THEN
      l_debug_on := WSH_DEBUG_SV.is_debug_enabled;
  END IF;
  --
  IF l_debug_on THEN
    --
    WSH_DEBUG_SV.push(l_module_name);
    WSH_DEBUG_SV.log(l_module_name,'p_in_rec.caller',p_in_rec.caller);
    --
  END IF;
  --
  x_return_status := FND_API.G_RET_STS_SUCCESS;
  --
  IF     p_user_in_rec.TRIP_ID <> FND_API.G_MISS_NUM
      AND NVL(p_user_in_rec.TRIP_ID,-99) <> NVL(p_out_rec.TRIP_ID,-99)
  THEN
       IF l_attributes IS NOT NULL THEN
          l_attributes := l_attributes || ', ';
       END IF;
       l_attributes := l_attributes || 'TRIP_ID';
  END IF;

  IF     p_user_in_rec.NAME <> FND_API.G_MISS_CHAR
      AND NVL(p_user_in_rec.NAME,'!!!') <> NVL(p_out_rec.NAME,'!!!')
  THEN
       IF l_attributes IS NOT NULL THEN
          l_attributes := l_attributes || ', ';
       END IF;
       l_attributes := l_attributes || 'NAME';
  END IF;

  IF     p_user_in_rec.PLANNED_FLAG <> FND_API.G_MISS_CHAR
      AND NVL(p_user_in_rec.PLANNED_FLAG,'!!!') <> NVL(p_out_rec.PLANNED_FLAG,'!!!')
  THEN
       IF l_attributes IS NOT NULL THEN
          l_attributes := l_attributes || ', ';
       END IF;
       l_attributes := l_attributes || 'PLANNED_FLAG';
  END IF;

  IF     p_user_in_rec.ARRIVE_AFTER_TRIP_ID <> FND_API.G_MISS_NUM
      AND NVL(p_user_in_rec.ARRIVE_AFTER_TRIP_ID,-99) <> NVL(p_out_rec.ARRIVE_AFTER_TRIP_ID,-99)
  THEN
       IF l_attributes IS NOT NULL THEN
          l_attributes := l_attributes || ', ';
       END IF;
       l_attributes := l_attributes || 'ARRIVE_AFTER_TRIP_ID';
  END IF;

  IF     p_user_in_rec.STATUS_CODE <> FND_API.G_MISS_CHAR
      AND NVL(p_user_in_rec.STATUS_CODE,'!!!') <> NVL(p_out_rec.STATUS_CODE,'!!!')
  THEN
       IF l_attributes IS NOT NULL THEN
          l_attributes := l_attributes || ', ';
       END IF;
       l_attributes := l_attributes || 'STATUS_CODE';
  END IF;

  IF     p_user_in_rec.VEHICLE_ITEM_ID <> FND_API.G_MISS_NUM
      AND NVL(p_user_in_rec.VEHICLE_ITEM_ID,-99) <> NVL(p_out_rec.VEHICLE_ITEM_ID,-99)
  THEN
       IF l_attributes IS NOT NULL THEN
          l_attributes := l_attributes || ', ';
       END IF;
       --DBMS_OUTPUT.PUT_LINE($$PLSQL_LINE);
       l_attributes := l_attributes || 'VEHICLE_ITEM_ID';
  END IF;

  IF     p_user_in_rec.VEHICLE_ORGANIZATION_ID <> FND_API.G_MISS_NUM
      AND NVL(p_user_in_rec.VEHICLE_ORGANIZATION_ID,-99) <> NVL(p_out_rec.VEHICLE_ORGANIZATION_ID,-99)
  THEN
       IF l_attributes IS NOT NULL THEN
          l_attributes := l_attributes || ', ';
       END IF;
       l_attributes := l_attributes || 'VEHICLE_ORGANIZATION_ID';
  END IF;

  IF     p_user_in_rec.VEHICLE_NUMBER <> FND_API.G_MISS_CHAR
      AND NVL(p_user_in_rec.VEHICLE_NUMBER,'!!!') <> NVL(p_out_rec.VEHICLE_NUMBER,'!!!')
  THEN
       IF l_attributes IS NOT NULL THEN
          l_attributes := l_attributes || ', ';
       END IF;
       l_attributes := l_attributes || 'VEHICLE_NUMBER';
  END IF;

  IF     p_user_in_rec.VEHICLE_NUM_PREFIX <> FND_API.G_MISS_CHAR
      AND NVL(p_user_in_rec.VEHICLE_NUM_PREFIX,'!!!') <> NVL(p_out_rec.VEHICLE_NUM_PREFIX,'!!!')
  THEN
       IF l_attributes IS NOT NULL THEN
          l_attributes := l_attributes || ', ';
       END IF;
       l_attributes := l_attributes || 'VEHICLE_NUM_PREFIX';
  END IF;

  IF     p_user_in_rec.CARRIER_ID <> FND_API.G_MISS_NUM
      AND NVL(p_user_in_rec.CARRIER_ID,-99) <> NVL(p_out_rec.CARRIER_ID,-99)
  THEN
       IF l_attributes IS NOT NULL THEN
          l_attributes := l_attributes || ', ';
       END IF;
       l_attributes := l_attributes || 'CARRIER_ID';
  END IF;

  IF     p_user_in_rec.SHIP_METHOD_CODE <> FND_API.G_MISS_CHAR
      AND NVL(p_user_in_rec.SHIP_METHOD_CODE,'!!!') <> NVL(p_out_rec.SHIP_METHOD_CODE,'!!!')
  THEN
       IF l_attributes IS NOT NULL THEN
          l_attributes := l_attributes || ', ';
       END IF;
       l_attributes := l_attributes || 'SHIP_METHOD_CODE';
  END IF;

  IF     p_user_in_rec.ROUTE_ID <> FND_API.G_MISS_NUM
      AND NVL(p_user_in_rec.ROUTE_ID,-99) <> NVL(p_out_rec.ROUTE_ID,-99)
  THEN
       IF l_attributes IS NOT NULL THEN
          l_attributes := l_attributes || ', ';
       END IF;
       l_attributes := l_attributes || 'ROUTE_ID';
  END IF;

  IF     p_user_in_rec.ROUTING_INSTRUCTIONS <> FND_API.G_MISS_CHAR
      AND NVL(p_user_in_rec.ROUTING_INSTRUCTIONS,'!!!') <> NVL(p_out_rec.ROUTING_INSTRUCTIONS,'!!!')
  THEN
       IF l_attributes IS NOT NULL THEN
          l_attributes := l_attributes || ', ';
       END IF;
       l_attributes := l_attributes || 'ROUTING_INSTRUCTIONS';
  END IF;

  IF     p_user_in_rec.ATTRIBUTE_CATEGORY <> FND_API.G_MISS_CHAR
      AND NVL(p_user_in_rec.ATTRIBUTE_CATEGORY,'!!!') <> NVL(p_out_rec.ATTRIBUTE_CATEGORY,'!!!')
  THEN
       IF l_attributes IS NOT NULL THEN
          l_attributes := l_attributes || ', ';
       END IF;
       l_attributes := l_attributes || 'ATTRIBUTE_CATEGORY';
  END IF;

  IF     p_user_in_rec.ATTRIBUTE1 <> FND_API.G_MISS_CHAR
      AND NVL(p_user_in_rec.ATTRIBUTE1,'!!!') <> NVL(p_out_rec.ATTRIBUTE1,'!!!')
  THEN
       IF l_attributes IS NOT NULL THEN
          l_attributes := l_attributes || ', ';
       END IF;
       l_attributes := l_attributes || 'ATTRIBUTE1';
  END IF;

  IF     p_user_in_rec.ATTRIBUTE2 <> FND_API.G_MISS_CHAR
      AND NVL(p_user_in_rec.ATTRIBUTE2,'!!!') <> NVL(p_out_rec.ATTRIBUTE2,'!!!')
  THEN
       IF l_attributes IS NOT NULL THEN
          l_attributes := l_attributes || ', ';
       END IF;
       l_attributes := l_attributes || 'ATTRIBUTE2';
  END IF;

  IF     p_user_in_rec.ATTRIBUTE3 <> FND_API.G_MISS_CHAR
      AND NVL(p_user_in_rec.ATTRIBUTE3,'!!!') <> NVL(p_out_rec.ATTRIBUTE3,'!!!')
  THEN
       IF l_attributes IS NOT NULL THEN
          l_attributes := l_attributes || ', ';
       END IF;
       l_attributes := l_attributes || 'ATTRIBUTE3';
  END IF;

  IF     p_user_in_rec.ATTRIBUTE4 <> FND_API.G_MISS_CHAR
      AND NVL(p_user_in_rec.ATTRIBUTE4,'!!!') <> NVL(p_out_rec.ATTRIBUTE4,'!!!')
  THEN
       IF l_attributes IS NOT NULL THEN
          l_attributes := l_attributes || ', ';
       END IF;
       l_attributes := l_attributes || 'ATTRIBUTE4';
  END IF;

  IF     p_user_in_rec.ATTRIBUTE5 <> FND_API.G_MISS_CHAR
      AND NVL(p_user_in_rec.ATTRIBUTE5,'!!!') <> NVL(p_out_rec.ATTRIBUTE5,'!!!')
  THEN
       IF l_attributes IS NOT NULL THEN
          l_attributes := l_attributes || ', ';
       END IF;
       l_attributes := l_attributes || 'ATTRIBUTE5';
  END IF;

  IF     p_user_in_rec.ATTRIBUTE6 <> FND_API.G_MISS_CHAR
      AND NVL(p_user_in_rec.ATTRIBUTE6,'!!!') <> NVL(p_out_rec.ATTRIBUTE6,'!!!')
  THEN
       IF l_attributes IS NOT NULL THEN
          l_attributes := l_attributes || ', ';
       END IF;
       l_attributes := l_attributes || 'ATTRIBUTE6';
  END IF;

  IF     p_user_in_rec.ATTRIBUTE7 <> FND_API.G_MISS_CHAR
      AND NVL(p_user_in_rec.ATTRIBUTE7,'!!!') <> NVL(p_out_rec.ATTRIBUTE7,'!!!')
  THEN
       IF l_attributes IS NOT NULL THEN
          l_attributes := l_attributes || ', ';
       END IF;
       l_attributes := l_attributes || 'ATTRIBUTE7';
  END IF;

  IF     p_user_in_rec.ATTRIBUTE8 <> FND_API.G_MISS_CHAR
      AND NVL(p_user_in_rec.ATTRIBUTE8,'!!!') <> NVL(p_out_rec.ATTRIBUTE8,'!!!')
  THEN
       IF l_attributes IS NOT NULL THEN
          l_attributes := l_attributes || ', ';
       END IF;
       l_attributes := l_attributes || 'ATTRIBUTE8';
  END IF;

  IF     p_user_in_rec.ATTRIBUTE9 <> FND_API.G_MISS_CHAR
      AND NVL(p_user_in_rec.ATTRIBUTE9,'!!!') <> NVL(p_out_rec.ATTRIBUTE9,'!!!')
  THEN
       IF l_attributes IS NOT NULL THEN
          l_attributes := l_attributes || ', ';
       END IF;
       l_attributes := l_attributes || 'ATTRIBUTE9';
  END IF;

  IF     p_user_in_rec.ATTRIBUTE10 <> FND_API.G_MISS_CHAR
      AND NVL(p_user_in_rec.ATTRIBUTE10,'!!!') <> NVL(p_out_rec.ATTRIBUTE10,'!!!')
  THEN
       IF l_attributes IS NOT NULL THEN
          l_attributes := l_attributes || ', ';
       END IF;
       l_attributes := l_attributes || 'ATTRIBUTE10';
  END IF;

  IF     p_user_in_rec.ATTRIBUTE11 <> FND_API.G_MISS_CHAR
      AND NVL(p_user_in_rec.ATTRIBUTE11,'!!!') <> NVL(p_out_rec.ATTRIBUTE11,'!!!')
  THEN
       IF l_attributes IS NOT NULL THEN
          l_attributes := l_attributes || ', ';
       END IF;
       l_attributes := l_attributes || 'ATTRIBUTE11';
  END IF;

  IF     p_user_in_rec.ATTRIBUTE12 <> FND_API.G_MISS_CHAR
      AND NVL(p_user_in_rec.ATTRIBUTE12,'!!!') <> NVL(p_out_rec.ATTRIBUTE12,'!!!')
  THEN
       IF l_attributes IS NOT NULL THEN
          l_attributes := l_attributes || ', ';
       END IF;
       l_attributes := l_attributes || 'ATTRIBUTE12';
  END IF;

  IF     p_user_in_rec.ATTRIBUTE13 <> FND_API.G_MISS_CHAR
      AND NVL(p_user_in_rec.ATTRIBUTE13,'!!!') <> NVL(p_out_rec.ATTRIBUTE13,'!!!')
  THEN
       IF l_attributes IS NOT NULL THEN
          l_attributes := l_attributes || ', ';
       END IF;
       l_attributes := l_attributes || 'ATTRIBUTE13';
  END IF;

  IF     p_user_in_rec.ATTRIBUTE14 <> FND_API.G_MISS_CHAR
      AND NVL(p_user_in_rec.ATTRIBUTE14,'!!!') <> NVL(p_out_rec.ATTRIBUTE14,'!!!')
  THEN
       IF l_attributes IS NOT NULL THEN
          l_attributes := l_attributes || ', ';
       END IF;
       l_attributes := l_attributes || 'ATTRIBUTE14';
  END IF;

  IF     p_user_in_rec.ATTRIBUTE15 <> FND_API.G_MISS_CHAR
      AND NVL(p_user_in_rec.ATTRIBUTE15,'!!!') <> NVL(p_out_rec.ATTRIBUTE15,'!!!')
  THEN
       IF l_attributes IS NOT NULL THEN
          l_attributes := l_attributes || ', ';
       END IF;
       l_attributes := l_attributes || 'ATTRIBUTE15';
  END IF;

  /**
  -- bug 3613650
  -- Need not compare against standard WHO columns
  IF     p_user_in_rec.CREATION_DATE <> FND_API.G_MISS_DATE
      AND NVL(p_user_in_rec.CREATION_DATE,TO_DATE('2','j')) <> NVL(p_out_rec.CREATION_DATE,TO_DATE('2','j'))
  THEN
       IF l_attributes IS NOT NULL THEN
          l_attributes := l_attributes || ', ';
       END IF;
       l_attributes := l_attributes || 'CREATION_DATE';
  END IF;

  IF     p_user_in_rec.CREATED_BY <> FND_API.G_MISS_NUM
      AND NVL(p_user_in_rec.CREATED_BY,-99) <> NVL(p_out_rec.CREATED_BY,-99)
  THEN
       IF l_attributes IS NOT NULL THEN
          l_attributes := l_attributes || ', ';
       END IF;
       l_attributes := l_attributes || 'CREATED_BY';
  END IF;

  IF     p_user_in_rec.LAST_UPDATE_DATE <> FND_API.G_MISS_DATE
      AND NVL(p_user_in_rec.LAST_UPDATE_DATE,TO_DATE('2','j')) <> NVL(p_out_rec.LAST_UPDATE_DATE,TO_DATE('2','j'))
  THEN
       IF l_attributes IS NOT NULL THEN
          l_attributes := l_attributes || ', ';
       END IF;
       l_attributes := l_attributes || 'LAST_UPDATE_DATE';
  END IF;

  IF     p_user_in_rec.LAST_UPDATED_BY <> FND_API.G_MISS_NUM
      AND NVL(p_user_in_rec.LAST_UPDATED_BY,-99) <> NVL(p_out_rec.LAST_UPDATED_BY,-99)
  THEN
       IF l_attributes IS NOT NULL THEN
          l_attributes := l_attributes || ', ';
       END IF;
       l_attributes := l_attributes || 'LAST_UPDATED_BY';
  END IF;

  IF     p_user_in_rec.LAST_UPDATE_LOGIN <> FND_API.G_MISS_NUM
      AND NVL(p_user_in_rec.LAST_UPDATE_LOGIN,-99) <> NVL(p_out_rec.LAST_UPDATE_LOGIN,-99)
  THEN
       IF l_attributes IS NOT NULL THEN
          l_attributes := l_attributes || ', ';
       END IF;
       l_attributes := l_attributes || 'LAST_UPDATE_LOGIN';
  END IF;

  IF     p_user_in_rec.PROGRAM_APPLICATION_ID <> FND_API.G_MISS_NUM
      AND NVL(p_user_in_rec.PROGRAM_APPLICATION_ID,-99) <> NVL(p_out_rec.PROGRAM_APPLICATION_ID,-99)
  THEN
       IF l_attributes IS NOT NULL THEN
          l_attributes := l_attributes || ', ';
       END IF;
       l_attributes := l_attributes || 'PROGRAM_APPLICATION_ID';
  END IF;

  IF     p_user_in_rec.PROGRAM_ID <> FND_API.G_MISS_NUM
      AND NVL(p_user_in_rec.PROGRAM_ID,-99) <> NVL(p_out_rec.PROGRAM_ID,-99)
  THEN
       IF l_attributes IS NOT NULL THEN
          l_attributes := l_attributes || ', ';
       END IF;
       l_attributes := l_attributes || 'PROGRAM_ID';
  END IF;

  IF     p_user_in_rec.PROGRAM_UPDATE_DATE <> FND_API.G_MISS_DATE
      AND NVL(p_user_in_rec.PROGRAM_UPDATE_DATE,TO_DATE('2','j')) <> NVL(p_out_rec.PROGRAM_UPDATE_DATE,TO_DATE('2','j'))
  THEN
       IF l_attributes IS NOT NULL THEN
          l_attributes := l_attributes || ', ';
       END IF;
       l_attributes := l_attributes || 'PROGRAM_UPDATE_DATE';
  END IF;

  IF     p_user_in_rec.REQUEST_ID <> FND_API.G_MISS_NUM
      AND NVL(p_user_in_rec.REQUEST_ID,-99) <> NVL(p_out_rec.REQUEST_ID,-99)
  THEN
       IF l_attributes IS NOT NULL THEN
          l_attributes := l_attributes || ', ';
       END IF;
       l_attributes := l_attributes || 'REQUEST_ID';
  END IF;

 bug 3613650 */

  IF     p_user_in_rec.SERVICE_LEVEL <> FND_API.G_MISS_CHAR
      AND NVL(p_user_in_rec.SERVICE_LEVEL,'!!!') <> NVL(p_out_rec.SERVICE_LEVEL,'!!!')
  THEN
       IF l_attributes IS NOT NULL THEN
          l_attributes := l_attributes || ', ';
       END IF;
       l_attributes := l_attributes || 'SERVICE_LEVEL';
  END IF;

  IF     p_user_in_rec.MODE_OF_TRANSPORT <> FND_API.G_MISS_CHAR
      AND NVL(p_user_in_rec.MODE_OF_TRANSPORT,'!!!') <> NVL(p_out_rec.MODE_OF_TRANSPORT,'!!!')
  THEN
       IF l_attributes IS NOT NULL THEN
          l_attributes := l_attributes || ', ';
       END IF;
       l_attributes := l_attributes || 'MODE_OF_TRANSPORT';
  END IF;

  IF     p_user_in_rec.FREIGHT_TERMS_CODE <> FND_API.G_MISS_CHAR
      AND NVL(p_user_in_rec.FREIGHT_TERMS_CODE,'!!!') <> NVL(p_out_rec.FREIGHT_TERMS_CODE,'!!!')
  THEN
       IF l_attributes IS NOT NULL THEN
          l_attributes := l_attributes || ', ';
       END IF;
       l_attributes := l_attributes || 'FREIGHT_TERMS_CODE';
  END IF;

  IF     p_user_in_rec.CONSOLIDATION_ALLOWED <> FND_API.G_MISS_CHAR
      AND NVL(p_user_in_rec.CONSOLIDATION_ALLOWED,'!!!') <> NVL(p_out_rec.CONSOLIDATION_ALLOWED,'!!!')
  THEN
       IF l_attributes IS NOT NULL THEN
          l_attributes := l_attributes || ', ';
       END IF;
       l_attributes := l_attributes || 'CONSOLIDATION_ALLOWED';
  END IF;

  IF     p_user_in_rec.LOAD_TENDER_STATUS <> FND_API.G_MISS_CHAR
      AND NVL(p_user_in_rec.LOAD_TENDER_STATUS,'!!!') <> NVL(p_out_rec.LOAD_TENDER_STATUS,'!!!')
  THEN
       IF l_attributes IS NOT NULL THEN
          l_attributes := l_attributes || ', ';
       END IF;
       l_attributes := l_attributes || 'LOAD_TENDER_STATUS';
  END IF;

  IF     p_user_in_rec.ROUTE_LANE_ID <> FND_API.G_MISS_NUM
      AND NVL(p_user_in_rec.ROUTE_LANE_ID,-99) <> NVL(p_out_rec.ROUTE_LANE_ID,-99)
  THEN
       IF l_attributes IS NOT NULL THEN
          l_attributes := l_attributes || ', ';
       END IF;
       l_attributes := l_attributes || 'ROUTE_LANE_ID';
  END IF;

  IF     p_user_in_rec.LANE_ID <> FND_API.G_MISS_NUM
      AND NVL(p_user_in_rec.LANE_ID,-99) <> NVL(p_out_rec.LANE_ID,-99)
  THEN
       IF l_attributes IS NOT NULL THEN
          l_attributes := l_attributes || ', ';
       END IF;
       l_attributes := l_attributes || 'LANE_ID';
  END IF;

  IF     p_user_in_rec.SCHEDULE_ID <> FND_API.G_MISS_NUM
      AND NVL(p_user_in_rec.SCHEDULE_ID,-99) <> NVL(p_out_rec.SCHEDULE_ID,-99)
  THEN
       IF l_attributes IS NOT NULL THEN
          l_attributes := l_attributes || ', ';
       END IF;
       l_attributes := l_attributes || 'SCHEDULE_ID';
  END IF;

  IF     p_user_in_rec.BOOKING_NUMBER <> FND_API.G_MISS_CHAR
      AND NVL(p_user_in_rec.BOOKING_NUMBER,'!!!') <> NVL(p_out_rec.BOOKING_NUMBER,'!!!')
  THEN
       IF l_attributes IS NOT NULL THEN
          l_attributes := l_attributes || ', ';
       END IF;
       l_attributes := l_attributes || 'BOOKING_NUMBER';
  END IF;

  IF     p_user_in_rec.ROWID <> FND_API.G_MISS_CHAR
      AND NVL(p_user_in_rec.ROWID,'!!!') <> NVL(p_out_rec.ROWID,'!!!')
  THEN
       IF l_attributes IS NOT NULL THEN
          l_attributes := l_attributes || ', ';
       END IF;
       l_attributes := l_attributes || 'ROWID';
  END IF;

  IF     p_user_in_rec.ARRIVE_AFTER_TRIP_NAME <> FND_API.G_MISS_CHAR
      AND NVL(p_user_in_rec.ARRIVE_AFTER_TRIP_NAME,'!!!') <> NVL(p_out_rec.ARRIVE_AFTER_TRIP_NAME,'!!!')
  THEN
       IF l_attributes IS NOT NULL THEN
          l_attributes := l_attributes || ', ';
       END IF;
       l_attributes := l_attributes || 'ARRIVE_AFTER_TRIP_NAME';
  END IF;

  IF     p_user_in_rec.SHIP_METHOD_NAME <> FND_API.G_MISS_CHAR
      AND NVL(p_user_in_rec.SHIP_METHOD_NAME,'!!!') <> NVL(p_out_rec.SHIP_METHOD_NAME,'!!!')
  THEN
       IF l_attributes IS NOT NULL THEN
          l_attributes := l_attributes || ', ';
       END IF;
       l_attributes := l_attributes || 'SHIP_METHOD_NAME';
  END IF;

  IF     p_user_in_rec.VEHICLE_ITEM_DESC <> FND_API.G_MISS_CHAR
      AND NVL(p_user_in_rec.VEHICLE_ITEM_DESC,'!!!') <> NVL(p_out_rec.VEHICLE_ITEM_DESC,'!!!')
  THEN
       IF l_attributes IS NOT NULL THEN
          l_attributes := l_attributes || ', ';
       END IF;
       l_attributes := l_attributes || 'VEHICLE_ITEM_DESC';
  END IF;

  IF     p_user_in_rec.VEHICLE_ORGANIZATION_CODE <> FND_API.G_MISS_CHAR
      AND NVL(p_user_in_rec.VEHICLE_ORGANIZATION_CODE,'!!!') <> NVL(p_out_rec.VEHICLE_ORGANIZATION_CODE,'!!!')
  THEN
       IF l_attributes IS NOT NULL THEN
          l_attributes := l_attributes || ', ';
       END IF;
       l_attributes := l_attributes || 'VEHICLE_ORGANIZATION_CODE';
  END IF;

  IF     p_user_in_rec.LOAD_TENDER_NUMBER <> FND_API.G_MISS_NUM
      AND NVL(p_user_in_rec.LOAD_TENDER_NUMBER,-99) <> NVL(p_out_rec.LOAD_TENDER_NUMBER,-99)
  THEN
       IF l_attributes IS NOT NULL THEN
          l_attributes := l_attributes || ', ';
       END IF;
       l_attributes := l_attributes || 'LOAD_TENDER_NUMBER';
  END IF;

  IF     p_user_in_rec.VESSEL <> FND_API.G_MISS_CHAR
      AND NVL(p_user_in_rec.VESSEL,'!!!') <> NVL(p_out_rec.VESSEL,'!!!')
  THEN
       IF l_attributes IS NOT NULL THEN
          l_attributes := l_attributes || ', ';
       END IF;
       l_attributes := l_attributes || 'VESSEL';
  END IF;

  IF     p_user_in_rec.VOYAGE_NUMBER <> FND_API.G_MISS_CHAR
      AND NVL(p_user_in_rec.VOYAGE_NUMBER,'!!!') <> NVL(p_out_rec.VOYAGE_NUMBER,'!!!')
  THEN
       IF l_attributes IS NOT NULL THEN
          l_attributes := l_attributes || ', ';
       END IF;
       l_attributes := l_attributes || 'VOYAGE_NUMBER';
  END IF;

  IF     p_user_in_rec.PORT_OF_LOADING <> FND_API.G_MISS_CHAR
      AND NVL(p_user_in_rec.PORT_OF_LOADING,'!!!') <> NVL(p_out_rec.PORT_OF_LOADING,'!!!')
  THEN
       IF l_attributes IS NOT NULL THEN
          l_attributes := l_attributes || ', ';
       END IF;
       l_attributes := l_attributes || 'PORT_OF_LOADING';
  END IF;

  IF     p_user_in_rec.PORT_OF_DISCHARGE <> FND_API.G_MISS_CHAR
      AND NVL(p_user_in_rec.PORT_OF_DISCHARGE,'!!!') <> NVL(p_out_rec.PORT_OF_DISCHARGE,'!!!')
  THEN
       IF l_attributes IS NOT NULL THEN
          l_attributes := l_attributes || ', ';
       END IF;
       l_attributes := l_attributes || 'PORT_OF_DISCHARGE';
  END IF;

  IF     p_user_in_rec.WF_NAME <> FND_API.G_MISS_CHAR
      AND NVL(p_user_in_rec.WF_NAME,'!!!') <> NVL(p_out_rec.WF_NAME,'!!!')
  THEN
       IF l_attributes IS NOT NULL THEN
          l_attributes := l_attributes || ', ';
       END IF;
       l_attributes := l_attributes || 'WF_NAME';
  END IF;

  IF     p_user_in_rec.WF_PROCESS_NAME <> FND_API.G_MISS_CHAR
      AND NVL(p_user_in_rec.WF_PROCESS_NAME,'!!!') <> NVL(p_out_rec.WF_PROCESS_NAME,'!!!')
  THEN
       IF l_attributes IS NOT NULL THEN
          l_attributes := l_attributes || ', ';
       END IF;
       l_attributes := l_attributes || 'WF_PROCESS_NAME';
  END IF;

  IF     p_user_in_rec.WF_ITEM_KEY <> FND_API.G_MISS_CHAR
      AND NVL(p_user_in_rec.WF_ITEM_KEY,'!!!') <> NVL(p_out_rec.WF_ITEM_KEY,'!!!')
  THEN
       IF l_attributes IS NOT NULL THEN
          l_attributes := l_attributes || ', ';
       END IF;
       l_attributes := l_attributes || 'WF_ITEM_KEY';
  END IF;

  IF     p_user_in_rec.CARRIER_CONTACT_ID <> FND_API.G_MISS_NUM
      AND NVL(p_user_in_rec.CARRIER_CONTACT_ID,-99) <> NVL(p_out_rec.CARRIER_CONTACT_ID,-99)
  THEN
       IF l_attributes IS NOT NULL THEN
          l_attributes := l_attributes || ', ';
       END IF;
       l_attributes := l_attributes || 'CARRIER_CONTACT_ID';
  END IF;

  IF     p_user_in_rec.SHIPPER_WAIT_TIME <> FND_API.G_MISS_NUM
      AND NVL(p_user_in_rec.SHIPPER_WAIT_TIME,-99) <> NVL(p_out_rec.SHIPPER_WAIT_TIME,-99)
  THEN
       IF l_attributes IS NOT NULL THEN
          l_attributes := l_attributes || ', ';
       END IF;
       l_attributes := l_attributes || 'SHIPPER_WAIT_TIME';
  END IF;

  IF     p_user_in_rec.WAIT_TIME_UOM <> FND_API.G_MISS_CHAR
      AND NVL(p_user_in_rec.WAIT_TIME_UOM,'!!!') <> NVL(p_out_rec.WAIT_TIME_UOM,'!!!')
  THEN
       IF l_attributes IS NOT NULL THEN
          l_attributes := l_attributes || ', ';
       END IF;
       l_attributes := l_attributes || 'WAIT_TIME_UOM';
  END IF;

  IF     p_user_in_rec.LOAD_TENDERED_TIME <> FND_API.G_MISS_DATE
      AND NVL(p_user_in_rec.LOAD_TENDERED_TIME,TO_DATE('2','j')) <> NVL(p_out_rec.LOAD_TENDERED_TIME,TO_DATE('2','j'))
  THEN
       IF l_attributes IS NOT NULL THEN
          l_attributes := l_attributes || ', ';
       END IF;
       l_attributes := l_attributes || 'LOAD_TENDERED_TIME';
  END IF;

  IF     p_user_in_rec.CARRIER_RESPONSE <> FND_API.G_MISS_CHAR
      AND NVL(p_user_in_rec.CARRIER_RESPONSE,'!!!') <> NVL(p_out_rec.CARRIER_RESPONSE,'!!!')
  THEN
       IF l_attributes IS NOT NULL THEN
          l_attributes := l_attributes || ', ';
       END IF;
       l_attributes := l_attributes || 'CARRIER_RESPONSE';
  END IF;

  IF     p_user_in_rec.SHIPMENTS_TYPE_FLAG <> FND_API.G_MISS_CHAR
      AND NVL(p_user_in_rec.SHIPMENTS_TYPE_FLAG,'!!!') <> NVL(p_out_rec.SHIPMENTS_TYPE_FLAG,'!!!')
  THEN
       IF l_attributes IS NOT NULL THEN
          l_attributes := l_attributes || ', ';
       END IF;
       l_attributes := l_attributes || 'SHIPMENTS_TYPE_FLAG';
  END IF;

  IF     p_user_in_rec.IGNORE_FOR_PLANNING <> FND_API.G_MISS_CHAR
      AND NVL(p_user_in_rec.IGNORE_FOR_PLANNING,'!!!') <> NVL(p_out_rec.IGNORE_FOR_PLANNING,'!!!')
  THEN
       IF l_attributes IS NOT NULL THEN
          l_attributes := l_attributes || ', ';
       END IF;
       l_attributes := l_attributes || 'IGNORE_FOR_PLANNING';
  END IF;

  IF     p_user_in_rec.TP_PLAN_NAME <> FND_API.G_MISS_CHAR
      AND NVL(p_user_in_rec.TP_PLAN_NAME,'!!!') <> NVL(p_out_rec.TP_PLAN_NAME,'!!!')
  THEN
       IF l_attributes IS NOT NULL THEN
          l_attributes := l_attributes || ', ';
       END IF;
       l_attributes := l_attributes || 'TP_PLAN_NAME';
  END IF;

  IF     p_user_in_rec.TP_TRIP_NUMBER <> FND_API.G_MISS_NUM
      AND NVL(p_user_in_rec.TP_TRIP_NUMBER,-99) <> NVL(p_out_rec.TP_TRIP_NUMBER,-99)
  THEN
       IF l_attributes IS NOT NULL THEN
          l_attributes := l_attributes || ', ';
       END IF;
       l_attributes := l_attributes || 'TP_TRIP_NUMBER';
  END IF;

  IF     p_user_in_rec.SEAL_CODE <> FND_API.G_MISS_CHAR
      AND NVL(p_user_in_rec.SEAL_CODE,'!!!') <> NVL(p_out_rec.SEAL_CODE,'!!!')
  THEN
       IF l_attributes IS NOT NULL THEN
          l_attributes := l_attributes || ', ';
       END IF;
       l_attributes := l_attributes || 'SEAL_CODE';
  END IF;

  IF     p_user_in_rec.OPERATOR <> FND_API.G_MISS_CHAR
      AND NVL(p_user_in_rec.OPERATOR,'!!!') <> NVL(p_out_rec.OPERATOR,'!!!')
  THEN
       IF l_attributes IS NOT NULL THEN
          l_attributes := l_attributes || ', ';
       END IF;
       l_attributes := l_attributes || 'OPERATOR';
  END IF;


  IF     p_user_in_rec.CONSIGNEE_CARRIER_AC_NO <> FND_API.G_MISS_CHAR
      AND NVL(p_user_in_rec.CONSIGNEE_CARRIER_AC_NO,'!!!') <> NVL(p_out_rec.CONSIGNEE_CARRIER_AC_NO,'!!!')
  THEN
       IF l_attributes IS NOT NULL THEN
          l_attributes := l_attributes || ', ';
       END IF;
       l_attributes := l_attributes || 'CONSIGNEE_CARRIER_AC_NO';
  END IF;

  IF     p_user_in_rec.CARRIER_REFERENCE_NUMBER <> FND_API.G_MISS_CHAR
      AND NVL(p_user_in_rec.CARRIER_REFERENCE_NUMBER,'!!!') <> NVL(p_out_rec.CARRIER_REFERENCE_NUMBER,'!!!')
  THEN
       IF l_attributes IS NOT NULL THEN
          l_attributes := l_attributes || ', ';
       END IF;
       l_attributes := l_attributes || 'CARRIER_REFERENCE_NUMBER';
  END IF;

  IF     p_user_in_rec.APPEND_FLAG <> FND_API.G_MISS_CHAR
      AND NVL(p_user_in_rec.APPEND_FLAG,'!!!') <> NVL(p_out_rec.APPEND_FLAG,'!!!')
  THEN
       IF l_attributes IS NOT NULL THEN
          l_attributes := l_attributes || ', ';
       END IF;
       l_attributes := l_attributes || 'APPEND_FLAG';
  END IF;


  IF     p_user_in_rec.RANK_ID <> FND_API.G_MISS_NUM
      AND NVL(p_user_in_rec.RANK_ID, -99) <> NVL(p_out_rec.RANK_ID,-99)
  THEN
       IF l_attributes IS NOT NULL THEN
          l_attributes := l_attributes || ', ';
       END IF;
       l_attributes := l_attributes || 'RANK_ID';
  END IF;

  IF     p_user_in_rec.ROUTING_RULE_ID <> FND_API.G_MISS_NUM
      AND NVL(p_user_in_rec.ROUTING_RULE_ID, -99) <> NVL(p_out_rec.ROUTING_RULE_ID,-99)
  THEN
       IF l_attributes IS NOT NULL THEN
          l_attributes := l_attributes || ', ';
       END IF;
       l_attributes := l_attributes || 'ROUTING_RULE_ID';
  END IF;


  IF l_debug_on THEN
       WSH_DEBUG_SV.log(l_module_name,'l_attributes',l_attributes);
       WSH_DEBUG_SV.log(l_module_name,'length(l_attributes)',length(l_attributes));
  END IF;


  IF l_attributes IS NULL    THEN
     --no message to be shown to the user
     IF l_debug_on THEN
       WSH_DEBUG_SV.pop(l_module_name);
     END IF;
     RETURN;
     --
  ELSE
     Wsh_Utilities.process_message(
                                    p_entity => 'TRIP',
                                    p_entity_name => NVL(p_out_rec.NAME,p_out_rec.TRIP_ID),
                                    p_attributes => l_attributes,
                                    x_return_status => l_return_status
				  );

     IF l_return_status IN (WSH_UTIL_CORE.G_RET_STS_ERROR,WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR)
     THEN
       x_return_status := l_return_status;
       IF l_debug_on THEN
         wsh_debug_sv.logmsg(l_module_name,'Error returned by wsh_utilities.process_message',WSH_DEBUG_SV.C_PROC_LEVEL);
         WSH_DEBUG_SV.logmsg(l_module_name,'Unexpected error has occured. Oracle error message is '|| SQLERRM,WSH_DEBUG_SV.C_UNEXPEC_ERR_LEVEL);
         wsh_debug_sv.pop(l_module_name);
       END IF;
       return;
     ELSE
       x_return_status := wsh_util_core.G_RET_STS_WARNING;
     END IF;
  END IF;



  IF l_debug_on THEN
    WSH_DEBUG_SV.pop(l_module_name);
  END IF;
  --


EXCEPTION
    WHEN OTHERS THEN
        x_return_status := WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR ;
        --
        IF l_debug_on THEN
           WSH_DEBUG_SV.pop(l_module_name,'EXCEPTION:OTHERS');
        END IF;
        --
END user_non_updatable_columns;

-- bug 3516052
-- -----------------------------------------------------------------------
-- Name
--   PROCEDURE Validate_Stop_Dates
-- Purpose
--   This procedure is to validate the planned dates of the stops in the trip.
--   It makes sure that the planned departure date of a stop precedes the
--   planned arrival date of the next stop. It should be called after
--   the date changes have been applied to database.
--  Bug 3782135
--   Planned Arrival Dates across stops should be in Order, in sync
--   with Stop Sequence Number(Inbound - Mixed trips, Outbound)
--
-- Input Parameters:
--   p_trip_id : The trip to be validated
--
--
-- Output Parameters:
--   x_return_status  - Success, Warning, Error, Unexpected Error
-- ----------------------------------------------------------------------

PROCEDURE Validate_Stop_Dates
    (   p_trip_id        IN   NUMBER,
        x_return_status  OUT  NOCOPY VARCHAR2,
--tkt
        p_caller        IN      VARCHAR2
    )
IS

-- Bug 4036204: cur.planned_departure_date =< nxt.planned_arrival_date is OK
-- as long as cur.planned_arrival_date < nxt.planned_arrival_date
CURSOR get_invalid_planned_dates IS
SELECT cur.stop_location_id cur_location_id,
       cur.physical_stop_id,
       cur.planned_arrival_date cur_arr_date,
       cur.planned_departure_date cur_dep_date,
       nxt.stop_location_id nxt_location_id,
       nxt.planned_arrival_date nxt_arr_date
FROM   wsh_trip_stops cur, wsh_trip_stops nxt
WHERE  cur.trip_id = p_trip_id
AND    cur.trip_id = nxt.trip_id
AND    cur.stop_id <> nxt.stop_id
AND (( cur.planned_departure_date > nxt.planned_arrival_date
       AND    cur.planned_arrival_date < nxt.planned_arrival_date
       AND    cur.status_code = 'OP'
       AND    nxt.status_code = 'OP')
     OR ( cur.planned_arrival_date = nxt.planned_arrival_date
       AND    cur.status_code = 'OP'
       AND    nxt.status_code = 'OP')
     OR ( cur.physical_stop_id = nxt.stop_id
          AND cur.stop_sequence_number + 1 <> nxt.stop_sequence_number
        ))
AND    rownum = 1;

l_invalid_planned_date  get_invalid_planned_dates%ROWTYPE;

-- Bug 3782135, try to find a stop with invalid planned arrival date
-- This cursor validates the planned arrival dates across stops
-- within a trip (valid for inbound mixed trips as well as outbound)
-- Compare the open stops with closed/arrived stops
-- on same trip
-- where open stop's sequence number > close/arrived stop's seq. number
-- and open stops's pl. arr. date <= closed/arrived stops' pl arr date
-- Select statement below makes sure no open stop has a planned arrival
-- date which is earlier than a closed/arrived stop's planned arrival date
-- Check for upper limit is in WSHSTTHB.pls - get_disabled_list
-- and WSHSTACB.pls - reset_stop_seq_numbers
-- Outbound Scenario, select statement
-- Stop id   Sequence   Status
--   10         1        CL
--   20         2        AR
--   30         3        OP
-- Inbound, Mixed Trip scenario, Handled in WSHSTTHB.pls - get_disabled_list
-- Stop id   Sequence   Status
--   10         1        CL
--   20         2        OP
--   30         3        CL
--   40         4        OP
--   50         5        OP
--   60         6        CL
CURSOR get_invalid_plarrival_dates IS
SELECT cur.planned_arrival_date cur_arr_date,
       cur.stop_location_id cur_location_id,
       cur.stop_id          cur_stop_id,
       cur.stop_sequence_number cur_stop_seq_num,
       prv.planned_arrival_date prv_arr_date
FROM   wsh_trip_stops cur,
       wsh_trip_stops prv
WHERE  cur.trip_id = p_trip_id
AND    cur.trip_id = prv.trip_id
AND    cur.stop_id <> prv.stop_id
AND    cur.planned_arrival_date <= prv.planned_arrival_date
AND    cur.status_code = 'OP'
AND    prv.status_code IN ('AR','CL')
AND    cur.stop_sequence_number > prv.stop_sequence_number
AND    rownum = 1;

l_invalid_plarrival_date  get_invalid_plarrival_dates%ROWTYPE;
l_found BOOLEAN;
-- End of Bug 3782135

CURSOR get_deliveries_to_unassign IS
SELECT leg.delivery_id
FROM wsh_delivery_legs leg,
     wsh_trip_stops   pickup,
     wsh_trip_stops   dropoff
WHERE pickup.trip_id = p_trip_id
AND   pickup.trip_id = dropoff.trip_id
AND   pickup.stop_id <> dropoff.stop_id
AND   pickup.status_code = 'OP'
AND   dropoff.status_code = 'OP'
AND   leg.pick_up_stop_id = pickup.stop_id
AND   leg.drop_off_stop_id = dropoff.stop_id
AND   dropoff.planned_arrival_date <= pickup.planned_arrival_date;

l_num_warn         NUMBER;
l_num_warn_total   NUMBER;
l_debug_on BOOLEAN;
l_del_to_unassign WSH_UTIL_CORE.Id_Tab_Type;
l_return_status  VARCHAR2(1);
--
l_module_name CONSTANT VARCHAR2(100) := 'wsh.plsql.' || G_PKG_NAME || '.' || 'Validate_Stop_Dates';
invalid_input             EXCEPTION;
invalid_stop_date         EXCEPTION;
invalid_arrival_date      EXCEPTION;
i                         NUMBER;
l_batchsize               NUMBER;

BEGIN

  -- initialize variables
  x_return_status := WSH_UTIL_CORE.G_RET_STS_SUCCESS;
  l_del_to_unassign.delete;
  l_num_warn := 0;
  l_batchsize := 1000;
  l_num_warn_total := 0;
  --
  l_debug_on := WSH_DEBUG_INTERFACE.g_debug;
  --

  IF l_debug_on IS NULL THEN
    l_debug_on := WSH_DEBUG_SV.is_debug_enabled;
  END IF;

  --
  IF l_debug_on THEN
    WSH_DEBUG_SV.push(l_module_name);
    WSH_DEBUG_SV.log(l_module_name,'Trip ID ', p_trip_id);
  END IF;

  -- SSN Change
  -- Date validations are applicable only for Profile option = PAD and not if it is set to SSN
  IF WSH_TRIPS_ACTIONS.GET_STOP_SEQ_MODE = WSH_INTERFACE_GRP.G_STOP_SEQ_MODE_SSN THEN
    IF l_debug_on THEN
      WSH_DEBUG_SV.logmsg(l_module_name,'Stop Sequence Mode is SSN');
      WSH_DEBUG_SV.pop(l_module_name);
    END IF;
    RETURN; -- these validations are not required for profile option of SSN
  END IF;

  IF p_trip_id is NULL THEN
       raise invalid_input;
  END IF;


  OPEN get_invalid_planned_dates;
  FETCH get_invalid_planned_dates INTO l_invalid_planned_date;

  IF get_invalid_planned_dates%FOUND THEN
    raise invalid_stop_date;
  END IF;
  CLOSE get_invalid_planned_dates;

  -- Bug 3782135
  IF l_debug_on THEN
    WSH_DEBUG_SV.log(l_module_name,'Before Validating Arrival Dates',p_trip_id);
  END IF;

  OPEN get_invalid_plarrival_dates;
  FETCH get_invalid_plarrival_dates
   INTO l_invalid_plarrival_date;
  l_found := get_invalid_plarrival_dates%FOUND;
  CLOSE get_invalid_plarrival_dates;
  IF l_debug_on THEN
    WSH_DEBUG_SV.log(l_module_name,'After Validating Arrival Dates',p_trip_id);
  END IF;

  IF l_found THEN
    IF l_debug_on THEN
      WSH_DEBUG_SV.log(l_module_name,'Stop ID',l_invalid_plarrival_date.cur_stop_id);
      WSH_DEBUG_SV.log(l_module_name,'Seq',l_invalid_plarrival_date.cur_stop_seq_num);
    END IF;
    raise invalid_arrival_date;
  END IF;
  -- End of Bug 3782135

  -- bulk collection

  OPEN get_deliveries_to_unassign;
  LOOP
     l_num_warn := 0;

     FETCH  get_deliveries_to_unassign BULK COLLECT INTO l_del_to_unassign LIMIT l_batchsize ;
     IF l_del_to_unassign.count > 0 THEN

       i := l_del_to_unassign.first;
       WHILE i is not NULL LOOP

          IF l_debug_on THEN
              WSH_DEBUG_SV.logmsg(l_module_name,'unassign delivery '|| l_del_to_unassign(i));
          END IF;

          FND_MESSAGE.SET_NAME('WSH','WSH_DEL_UNASSIGN_TRIP');
          FND_MESSAGE.SET_TOKEN('DELIVERY_NAME',
                            WSH_NEW_DELIVERIES_PVT.get_name(l_del_to_unassign(i)));
          FND_MESSAGE.SET_TOKEN('TRIP_NAME',
                            WSH_TRIPS_PVT.get_name(p_trip_id));
          l_num_warn := l_num_warn + 1;
          WSH_UTIL_CORE.ADD_MESSAGE(WSH_UTIL_CORE.G_RET_STS_WARNING);

       i :=  l_del_to_unassign.next(i);
       END LOOP;

       IF l_debug_on THEN
           WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit WSH_TRIPS_ACTIONS.UNASSIGN_TRIP',WSH_DEBUG_SV.C_PROC_LEVEL);
       END IF;

       WSH_TRIPS_ACTIONS.unassign_trip
         (p_del_rows => l_del_to_unassign,
          p_trip_id  => p_trip_id,
          x_return_status => l_return_status);

       IF l_return_status in (WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR, WSH_UTIL_CORE.G_RET_STS_ERROR) THEN
          x_return_status := WSH_UTIL_CORE.G_RET_STS_ERROR;
          IF l_debug_on THEN
	    WSH_DEBUG_SV.pop(l_module_name);
          END IF;
          return;
       ELSIF l_return_status = WSH_UTIL_CORE.G_RET_STS_WARNING THEN
          l_num_warn := l_num_warn + 1;
       END IF;

       l_num_warn_total := l_num_warn_total + 1;
       l_del_to_unassign.delete;

     END IF;

     EXIT WHEN get_deliveries_to_unassign%NOTFOUND;
  END LOOP;
  CLOSE  get_deliveries_to_unassign;

  -- bulk collection

  IF l_num_warn_total > 0 THEN
    x_return_status := WSH_UTIL_CORE.G_RET_STS_WARNING;
  END IF;

  IF l_debug_on THEN
    WSH_DEBUG_SV.pop(l_module_name);
  END IF;

EXCEPTION

   WHEN invalid_input THEN
      x_return_status := WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR;
      FND_MESSAGE.SET_NAME('WSH', 'WSH_TRIP_ID_REQUIRED');
      wsh_util_core.add_message(x_return_status, l_module_name);
      IF l_debug_on THEN
          WSH_DEBUG_SV.logmsg(l_module_name,'ERROR: Trip ID is NULL');
          WSH_DEBUG_SV.pop(l_module_name,'EXCEPTION:invalid_input');
      END IF;

   WHEN invalid_stop_date THEN
      IF get_invalid_planned_dates%ISOPEN THEN
         close get_invalid_planned_dates;
      END IF;
      x_return_status := WSH_UTIL_CORE.G_RET_STS_ERROR;
      IF l_invalid_planned_date.physical_stop_id is NULL THEN
         FND_MESSAGE.SET_NAME('WSH', 'WSH_STOP_DATE_OVERLAP');
         FND_MESSAGE.SET_TOKEN('CURRENT_STOP_DATE', fnd_date.date_to_displaydt(l_invalid_planned_date.cur_dep_date,calendar_aware=>FND_DATE.calendar_aware_alt));
         FND_MESSAGE.SET_TOKEN('CURRENT_LOCATION_DESP',
         WSH_UTIL_CORE.Get_Location_Description (l_invalid_planned_date.cur_location_id,'NEW UI CODE INFO'));
         FND_MESSAGE.SET_TOKEN('NEXT_STOP_DATE', fnd_date.date_to_displaydt(l_invalid_planned_date.nxt_arr_date,calendar_aware=>FND_DATE.calendar_aware_alt));
      ELSE
         -- No stop is allowed between dummy stop and physical stop.
         FND_MESSAGE.SET_NAME('WSH', 'WSH_BETWEEN_LINKED_STOPS');
         FND_MESSAGE.SET_TOKEN('DUMMY_STOP_DATE', fnd_date.date_to_displaydt(l_invalid_planned_date.cur_arr_date,calendar_aware=>FND_DATE.calendar_aware_alt));
         FND_MESSAGE.SET_TOKEN('DUMMY_LOCATION_DESP',
            WSH_UTIL_CORE.Get_Location_Description (l_invalid_planned_date.cur_location_id,'NEW UI CODE INFO'));
         FND_MESSAGE.SET_TOKEN('PHYSICAL_STOP_DATE', fnd_date.date_to_displaydt(l_invalid_planned_date.nxt_arr_date,calendar_aware=>FND_DATE.calendar_aware_alt));
         FND_MESSAGE.SET_TOKEN('PHYSICAL_LOCATION_DESP',
            WSH_UTIL_CORE.Get_Location_Description (l_invalid_planned_date.nxt_location_id,'NEW UI CODE INFO'));
      END IF;
      wsh_util_core.add_message(x_return_status, l_module_name);

      IF l_debug_on THEN
          WSH_DEBUG_SV.pop(l_module_name,'EXCEPTION:invalid_stop_date');
      END IF;

   -- Bug 3782135
   WHEN invalid_arrival_date THEN
      x_return_status := WSH_UTIL_CORE.G_RET_STS_ERROR;

      FND_MESSAGE.SET_NAME('WSH', 'WSH_INVALID_STOP_DATE');
      FND_MESSAGE.SET_TOKEN('STOP_NAME',wsh_trip_stops_pvt.get_name(l_invalid_plarrival_date.cur_stop_id,p_caller));
      wsh_util_core.add_message(wsh_util_core.g_ret_sts_error, l_module_name);

      IF l_debug_on THEN
        WSH_DEBUG_SV.pop(l_module_name,'EXCEPTION:invalid_planned_arrival_date');
      END IF;

   -- End of Bug 3782135
   WHEN Others THEN
      IF get_invalid_planned_dates%ISOPEN THEN
        close get_invalid_planned_dates;
      END IF;
      -- Bug 3782135
      IF get_invalid_plarrival_dates%ISOPEN THEN
         close get_invalid_plarrival_dates;
      END IF;
      -- End of Bug 3782135

      IF get_deliveries_to_unassign%ISOPEN THEN
        close get_deliveries_to_unassign;
      END IF;
      wsh_util_core.default_handler('WSH_TRIP_STOPS_VALIDATIONS.Validate_Stop_Dates',l_module_name);
      x_return_status := WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR;
      IF l_debug_on THEN
          WSH_DEBUG_SV.pop(l_module_name,'EXCEPTION:OTHERS');
      END IF;

END Validate_Stop_Dates;

END WSH_TRIP_VALIDATIONS;
