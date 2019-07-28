import mutate from '../utils/mutate';
import Web3Service from '../services/Web3Service';


const domainParams = [
    {
        name: 'name',
        type: 'string',
    },
    {
        name: 'version',
        type: 'string',
    },
    {
        name: 'chainId',
        type: 'uint256',
    },
    {
        name: 'verifyingContract',
        type: 'address',
    },
    {
        name: 'salt',
        type: 'bytes32',
    },
];

const AZTECAccount = [
    {
        name: 'account',
        type: 'address',
    },
    {
        name: 'linkedPublicKey',
        type: 'bytes',
    },
];


export default {
    login: ({
        password,
    }) => mutate(`
        login(password: "${password}")
    `),
    registerExtension: async ({ password, salt }) => {
        const { address } = Web3Service.account;
        const response = await mutate(`
            registerExtension(password: "${password}", salt: "${salt}", address: "${address}") {
                account {
                    linkedPublicKey
                }
            }
        `);
        const {
            registerExtension: {
                account: {
                    linkedPublicKey,
                } = {},
            },
        } = response;

        const accountRegistryContract = Web3Service.contract('AZTECAccountRegistry');
        const domainData = {
            name: 'AZTECAccountRegistry',
            version: '2',
            chainId: 1563905255267,
            verifyingContract: accountRegistryContract.address,
            salt: '0xf2d857f4a3edcb9b78b4d503bfe733db1e3f6cdc2b7971ee739626c97e86a558',
        };

        const message = {
            account: address,
            linkedPublicKey,
        };

        const data = JSON.stringify({
            types: {
                EIP712Domain: domainParams,
                AZTECAccount,
            },
            domain: domainData,
            primaryType: 'AZTECAccount',
            message,
        });


        const { result } = await Web3Service.sendAsync({
            method: 'eth_signTypedData_v3',
            params: [address, data],
            from: address,
        });

        const signature = result.substring(2);
        const r = `0x${signature.substring(0, 64)}`;
        const s = `0x${signature.substring(64, 128)}`;
        const v = parseInt(signature.substring(128, 130), 16);

        await Web3Service
            .useContract('AZTECAccountRegistry', Web3Service.deployed('AZTECAccountRegistry').address)
            .method('registerAZTECExtension')
            .send(address, linkedPublicKey, v, r, s);
    },
    registerAddress: async (address) => {
        const {
            registerAddress,
        } = await mutate(`
            registerAddress(address: "${address}") {
                account {
                    address
                    linkedPublicKey
                }
                error {
                    type
                    key
                    message
                    response
                }
            }
        `);

        return registerAddress;
    },
    enableAsset: async (asset) => {
        const {
            enableAssetForDomain,
        } = await mutate(`
            enableAssetForDomain(asset: "${asset}") {
                asset {
                    address
                    linkedTokenAddress
                }
                error {
                    type
                    key
                    message
                    response
                }
            }
        `);

        return enableAssetForDomain;
    },
};