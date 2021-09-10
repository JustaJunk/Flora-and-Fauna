import { ethers } from "ethers";

module.exports = async ({
    getNamedAccounts,
    deployments,
    getChainId,
    getUnnamedAccounts,
  }) => {
    const chainId = await getChainId();

    if (chainId === '1337') {
        const { deploy, execute } = deployments;
        const { deployer } = await getNamedAccounts();

        const ens = await deploy("MockEnsRegistry", { from: deployer })
        console.log("ENS deployed to:", ens.address);

        const resolver = await deploy("MockPublicResolver", { from: deployer })
        console.log("Resolver deployed to:", resolver.address);

        const mockPairs = ['eth-usd', 'btc-usd', 'bnb-usd', 'link-usd'];
        const mockPrices = [3500, 50000, 400, 30];

        mockPairs.map(async (pair, idx) => {
            const namehash = ethers.utils.namehash(pair + ".data.eth");
            console.log(idx, pair, namehash);
            execute(
                "MockEnsRegistry", {from: deployer},
                "setResolver", namehash, resolver.address
            )
            
            const mockAgg = await deploy("MockV3Aggregator", {
                from: deployer,
                args:[1, mockPrices[idx]*10**8]
            })
            console.log(pair, "Aggregator deployed to:", mockAgg.address);                
            execute(
                "MockPublicResolver", {from: deployer},
                "setAddr", namehash, mockAgg.address
            )
        })
    }    
};
  