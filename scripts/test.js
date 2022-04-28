const fs = require('fs');
let rawdata = fs.readFileSync('D:/Programs/TOKEN/build/contracts/abi.json');

var Address = '0x5a53fec38120b413f8F27e121Da44A0B4e353016';
var ABI = JSON.parse(rawdata);

module.exports = function() {
    var contract = new web3.eth.Contract(ABI, Address);
    var batch = new web3.BatchRequest();
    const account = '0x5a53fec38120b413f8F27e121Da44A0B4e353016'; //'0x22ccead48c771bb2c7dc4d5ab21f0d5750eaad95';
    // batch.add(web3.eth.getAccounts.request((error, accounts) => {
    //     if (error) throw error;
    //     console.log(accounts);
    //     callback();
    // }));

    batch.add(web3.eth.getBalance.request(account, 'latest', (error, balance) => {
        if (error) throw error;
        console.log(balance);
    }));

    batch.add(contract.methods.balanceOf(account).call.request({from: account}, (error, balance) => {
        if (error) throw error;
        console.log(balance);
    }));

    batch.execute();

    //callback();
}