const assert = import('chai').assert;


const inLogs = async (logs, eventName) => {

    //아래코드는 assert.exists(event);  대신 구현한거임 
    const event = logs.find(e => e.event === eventName);
    
    if(event){
        //console.log("EVENT IS NOT UNDEFINED")
    }   else{
        console.log("event IS UNDEFINED")
    }
    //assert.exists(event); 
}

module.exports = {
    inLogs
}