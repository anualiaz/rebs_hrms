// Local mock API: node mock_api/server.js
// Scenarios: ?scenario=slow, ?scenario=error, ?scenario=duplicate, ?scenario=leave-reject
const http = require('http');
const url = require('url');
const PORT = 3000;
const events = new Map();
const leaves = [];
const employee = {id:'EMP-001',name:'Alex Johnson',department:'Engineering',
  officeName:'REBS Main Office',officeLat:9.974696,officeLng:76.487026,timezone:'Asia/Kolkata'};
function send(res,status,data){res.writeHead(status,{'content-type':'application/json','access-control-allow-origin':'*'});res.end(JSON.stringify(data));}
const server=http.createServer(async(req,res)=>{
  if(req.method==='OPTIONS'){res.writeHead(204,{'access-control-allow-origin':'*','access-control-allow-methods':'GET,POST,OPTIONS','access-control-allow-headers':'content-type'});return res.end();}
  const parsed=url.parse(req.url,true), path=parsed.pathname, scenario=parsed.query.scenario;
  if(scenario==='slow') await new Promise(r=>setTimeout(r,10000));
  if(scenario==='error'){return send(res,500,{message:'Simulated server error'});}
  let body='';for await(const chunk of req) body+=chunk;
  const data=body?JSON.parse(body):{};
  const TOTAL_LEAVE_BALANCE = 12;

  function calculateLeaveDays(startDate, endDate) {
    const start = new Date(startDate + 'T00:00:00Z');
    const end = new Date(endDate + 'T00:00:00Z');

    return Math.floor((end - start) / 86400000) + 1;
  }

  function getAvailableLeaveBalance() {
    const usedDays = leaves
      .filter(leave =>
        leave.status === 'Pending' ||
        leave.status === 'Approved'
      )
      .reduce((total, leave) => {
        return total + calculateLeaveDays(
          leave.startDate,
          leave.endDate
        );
      }, 0);

    return Math.max(0, TOTAL_LEAVE_BALANCE - usedDays);
  }

  if(req.method==='GET'&&path==='/employee/me') return send(res,200,employee);
  if(req.method==='GET'&&path==='/attendance') return send(res,200,[...events.values()].map(({status,...e})=>e));
  if (req.method === 'GET' && path === '/leave/balance') {
    return send(res, 200, {
      available: getAvailableLeaveBalance()
    });
  }
  if(req.method==='GET'&&path==='/leave/requests') return send(res,200,leaves);
  if(req.method==='POST'&&path==='/attendance/events'){
    if(events.has(data.id)) return send(res,200,{accepted:true,id:data.id,replayed:true});
    if(scenario==='duplicate') return send(res,409,{message:'Attendance already exists for this day'});
    events.set(data.id,{...data,status:'synced'});return send(res,201,{accepted:true,id:data.id});
  }
  if (req.method === 'POST' && path === '/leave/requests') {
    if (scenario === 'leave-reject') {
      return send(res, 422, {
        message: 'Leave request rejected by mock validation.'
      });
    }

    const start = new Date(data.startDate);
    const end = new Date(data.endDate);

    // 1. Validate date range
    if (isNaN(start.getTime()) || isNaN(end.getTime()) || end < start) {
      return send(res, 422, {
        message: 'Invalid leave dates.'
      });
    }

    // 2. Check overlapping leave requests
    const overlap = leaves.some(l =>
      ['Pending', 'Approved'].includes(l.status) &&
      !(end < new Date(l.startDate) || start > new Date(l.endDate))
    );

    if (overlap) {
      return send(res, 422, {
        message: 'Dates overlap an existing request.'
      });
    }

    // 3. Calculate requested leave days
    const requestedDays = calculateLeaveDays(
      data.startDate,
      data.endDate
    );

    // 4. Validate available leave balance
    if (requestedDays > getAvailableLeaveBalance()) {
      return send(res, 422, {
        message: 'Insufficient leave balance.'
      });
    }

    // 5. Save leave request
    const saved = {
      ...data,
      status: 'Pending'
    };

    leaves.push(saved);

    return send(res, 201, saved);
  }
  send(res,404,{message:'Endpoint not found'});
});
server.listen(PORT,()=>console.log(`REBS mock API listening on http://localhost:${PORT}`));
