require("dotenv").config();
const API_URL = process.env.API_URL;

const PUBLIC_KEY = process.env.PUBLIC_KEY;
const PRIVATE_KEY = process.env.PRIVATE_KEY;

const { createAlchemyWeb3 } = require("@alch/alchemy-web3");
const web3 = createAlchemyWeb3(API_URL);

const contract = require("../artifacts/contracts/MyNFT.sol/MyNFT.json");
// console.log(JSON.stringify(contract.abi)); 

const contractAddress = "0x457Da8a40DAC9a71059BbC56380044A2c8c8a2F4";
const nftContract = new web3.eth.Contract(contract.abi, contractAddress); // instance of the contract

// to create transaction
async function mintNFT(tokenURI) {
    const nonce = await web3.eth.getTransactionCount(PUBLIC_KEY, "latest");
    // const tx = nftContract.methods.mintNFT(tokenURI);
    // const txData = tx.encodeABI();
    const tx = {
            'from': PUBLIC_KEY,
            'to': contractAddress,
            'nonce': nonce,
            'gas': "1000000",
            'data': nftContract.methods.mintNFT(PUBLIC_KEY, tokenURI).encodeABI(),

        }
        // console.log(txReceipt);


    const signPromise = web3.eth.accounts.signTransaction(tx, PRIVATE_KEY);
    signPromise
        .then((signedTx) => {
            web3.eth.sendSignedTransaction(
                signedTx.rawTransaction,
                function(err, hash) {
                    if (!err) {
                        console.log(
                            "The hash of your transaction is: ",
                            hash,
                            "\nCheck Alchemy's Mempool to view the status of your transaction!"
                        );
                    } else {
                        console.log(
                            "Something went wrong when submitting your transaction:",
                            err
                        );
                    }
                }
            );
        })
        .catch((err) => {
            console.log(" Promise failed:", err);
        });

}

mintNFT(
    "https://gateway.pinata.cloud/ipfs/QmVddyeYgXM9BSyJNB2MkxmEkQzDfw7Kc7aoSSPgYJvZcL"
);