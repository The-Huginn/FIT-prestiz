import { assert, expect } from 'chai'
import { tokens, ether, wait, toBN, ETHER_ADDRESS, EVM_REVERT, EVM_SENDER_ERR } from '../helpers/helpers.js'

const LendingPool = artifacts.require('LendingPool');
const Token = artifacts.require('Token');

require('chai').use(require('chai-as-promised')).should();

contract('LendingPool', accounts => {
    let lendingPool;
    let token1;
    let token2;
    const decimals = 1000000;

    beforeEach(async() => {
        lendingPool = await LendingPool.new();

        token1 = await Token.new(accounts[7], accounts[8], accounts[9]);
        await lendingPool.InitializeReserve(
            token1.address,
            0,
            0.35 * decimals,    // 35% to fixed rating     
            0.35 * decimals,    // 35% to fixed rating 
            0.40 * decimals,    // 40% for deposit to borrow ratio
            0.10 * decimals,    // 10% for health ratio
            6                   // 6 decimals
        );
        await lendingPool.InitializeAvailability(
            token1.address,
            true,
            true,
            true
        );
        token2 = await Token.new(accounts[7], accounts[8], accounts[9]);
        await lendingPool.InitializeReserve(
            token2.address,
            0,
            0.35 * decimals,    // 35% to fixed rating     
            0.35 * decimals,    // 35% to fixed rating 
            0.40 * decimals,    // 40% for deposit to borrow ratio
            0.10 * decimals,    // 10% for health ratio
            6                   // 6 decimals
        );
        await lendingPool.InitializeAvailability(
            token2.address,
            true,
            true,
            true
        );
    })

    // describe('Testing deposit and withdrawal...', () => {
    //     it('should deposit funds to the user', async() => {
    //         await lendingPool.deposit(token1.address, tokens(1).toString(), { from: accounts[0]});
    //         var res = await lendingPool.getUserBalance(accounts[0], token1.address);
    //         expect(res[0].toString()).to.be.eq(tokens(1).toString());
    //     })
    //     it('should deposit funds to the reserve', async() => {
    //         await lendingPool.deposit(token1.address, tokens(1).toString(), {from: accounts[0]});
    //         var res = await lendingPool.getReserveBalance(token1.address);
    //         expect(res[0].toString()).to.be.eq(tokens(1).toString());
    //     })
    //     it('should deposit multiple tokens to the user', async() => {
    //         await lendingPool.deposit(token1.address, tokens(1).toString(), {from: accounts[0]});
    //         await lendingPool.deposit(token1.address, tokens(1.5).toString(), {from: accounts[0]});
    //         await lendingPool.deposit(token2.address, tokens(0.5).toString(), {from: accounts[0]});
    //         await lendingPool.deposit(token2.address, tokens(0.75).toString(), {from: accounts[0]});
    //         var res1 = await lendingPool.getUserBalance(accounts[0], token1.address);
    //         var res2 = await lendingPool.getUserBalance(accounts[0], token2.address);
    //         expect(res1[0].toString()).to.be.eq(tokens(2.5).toString());
    //         expect(res2[0].toString()).to.be.eq(tokens(1.25).toString());
    //     })
    //     it('should deposit multiple tokens to the reserve', async() => {
    //         await lendingPool.deposit(token1.address, tokens(1).toString(), {from: accounts[0]});
    //         await lendingPool.deposit(token1.address, tokens(1.5).toString(), {from: accounts[0]});
    //         await lendingPool.deposit(token2.address, tokens(0.5).toString(), {from: accounts[0]});
    //         await lendingPool.deposit(token2.address, tokens(0.75).toString(), {from: accounts[0]});
    //         var res1 = await lendingPool.getReserveBalance(token1.address);
    //         var res2 = await lendingPool.getReserveBalance(token2.address);
    //         expect(res1[0].toString()).to.be.eq(tokens(2.5).toString());
    //         expect(res2[0].toString()).to.be.eq(tokens(1.25).toString());
    //     })

    //     it('should withdraw funds to the user', async() => {
    //         await lendingPool.deposit(token1.address, tokens(1).toString(), {from: accounts[0]})
    //         await lendingPool.withdraw(token1.address, tokens(0.65).toString(), {from: accounts[0]});
    //         var res = await lendingPool.getUserBalance(accounts[0], token1.address);
    //         expect(res[0].toString()).to.be.eq(tokens(0.35).toString());
    //     })
    //     it('should withdraw funds from the reserve', async() => {
    //         await lendingPool.deposit(token1.address, tokens(1).toString(), {from: accounts[0]})
    //         await lendingPool.withdraw(token1.address, tokens(0.65).toString(), {from: accounts[0]});
    //         var res = await lendingPool.getReserveBalance(token1.address);
    //         expect(res[0].toString()).to.be.eq(tokens(0.35).toString());
    //     })
    // })

    describe('Testing borrow and repay...', () => {
        it('should allow and set user\'s borrow', async() => {
            await lendingPool.deposit(token1.address, tokens(1).toString(), {from: accounts[0]});
            await lendingPool.borrow(token1.address, token1.address, tokens(0.15).toString(), 1, {from: accounts[0]});
            var res = await lendingPool.getUserBorrow(accounts[0], token1.address);
            let expectedInterests = [31154, 10903, 253850, 342697];

            expect(res[0].toString()).to.be.eq(tokens(0.15).toString());
            expect(res[2].toString()).to.be.eq('1');
            expect(res[3].toString()).to.be.eq(expectedInterests[3].toString());
            expect(res[4].toString()).to.be.eq(token1.address);
        })
        it('should update reserve with borrow and it\'s interest rates', async() => {
            await lendingPool.deposit(token1.address, tokens(1).toString(), {from: accounts[0]});
            await lendingPool.borrow(token1.address, token1.address, tokens(0.15).toString(), 1, {from: accounts[0]});
            var res = await lendingPool.getReserveBalance(token1.address);
            let expectedInterests = [31154, 10903, 253850, 342697]
            let interests = await lendingPool.getReserveInterests(token1.address);
            for (let i = 0; i < expectedInterests.length; i++)
            {
                expect(interests[i].toString()).to.be.eq(expectedInterests[i].toString());
            }
            expect(res[1].toString()).to.be.eq(tokens(0.15).toString());
        })
        it('should deny borrow by reserve', async() => {
            await lendingPool.borrow(token1.address, token1.address, tokens(0.15).toString(), 1, {from: accounts[0]}).should.be.rejectedWith(EVM_REVERT);
        })
        it('should allow multiple borrows with the same collateral', async() => {
            await lendingPool.deposit(token1.address, tokens(1).toString(), {from: accounts[0]});
            await lendingPool.borrow(token1.address, token1.address, tokens(0.15).toString(), 1, {from: accounts[0]});
            await lendingPool.borrow(token1.address, token1.address, tokens(0.15).toString(), 1, {from: accounts[0]});

            var res = await lendingPool.getUserBorrow(accounts[0], token1.address);

            expect(res[0].toString()).to.be.eq(tokens(0.3).toString());
        })
        it('should deny to borrow with another collateral', async() => {
            await lendingPool.deposit(token1.address, tokens(1).toString(), {from: accounts[0]});
            await lendingPool.borrow(token1.address, token1.address, tokens(0.15).toString(), 1, {from: accounts[0]});
            await lendingPool.borrow(token2.address, token1.address, tokens(0.15).toString(), 1, {from: accounts[0]}).should.be.rejectedWith(EVM_REVERT);
        })
        it('should accrue interest to user', async() => {
            await lendingPool.deposit(token1.address, tokens(1).toString(), {from: accounts[0]});
            await lendingPool.borrow(token1.address, token1.address, tokens(0.15).toString(), 1, {from: accounts[0]});

            await wait(1.99);

            await lendingPool.deposit(token1.address, tokens(1).toString(), {from: accounts[0]});
            var res = await lendingPool.getUserBorrow(accounts[0], token1.address);
            // with such a small time window the error is almost 6%
            expect(res[1].toString()).to.be.eq('3084273000');
        })
        it('should allow user to repay the debt', async() => {
            await lendingPool.deposit(token1.address, tokens(1).toString(), {from: accounts[0]});
            await lendingPool.borrow(token1.address, token1.address, tokens(0.15).toString(), 1, {from: accounts[0]});

            await wait(1.99);

            await lendingPool.repay(token1.address, token1.address, tokens(0.15).toString(), {from: accounts[0]});
            var res = await lendingPool.getUserBorrow(accounts[0], token1.address);

            expect(res[0].toString()).to.be.eq('3084273000');
            expect(res[1].toString()).to.be.eq('0');

            await lendingPool.repay(token1.address, token1.address, 3084273000, {from: accounts[0]});
            res = await lendingPool.getUserBorrow(accounts[0], token1.address);

            expect(res[0].toString()).to.be.eq('0');
            expect(res[1].toString()).to.be.eq('0');
        })
        it('should allow borrow with another collateral after full repayment', async() => {
            await lendingPool.deposit(token1.address, tokens(1).toString(), {from: accounts[0]});
            await lendingPool.borrow(token1.address, token1.address, tokens(0.15).toString(), 1, {from: accounts[0]});

            await wait(1.99);

            await lendingPool.repay(token1.address, token1.address, tokens(0.15).toString(), {from: accounts[0]});
            await lendingPool.repay(token1.address, token1.address, 3084273000, {from: accounts[0]});
            var res = await lendingPool.getUserBorrow(accounts[0], token1.address);

            await lendingPool.borrow(token2.address, token1.address, tokens(0.15).toString(), 1, {from: accounts[0]});

            res = await lendingPool.getUserBorrow(accounts[0], token1.address);
            expect(res[0].toString()).to.be.eq(tokens(0.15).toString());
        })
        it('shouldn\'t allow borrow with another collateral before full repayment', async() => {
            await lendingPool.deposit(token1.address, tokens(1).toString(), {from: accounts[0]});
            await lendingPool.borrow(token1.address, token1.address, tokens(0.15).toString(), 1, {from: accounts[0]});

            await wait(1.99);

            await lendingPool.repay(token1.address, token1.address, tokens(0.15).toString(), {from: accounts[0]});
            var res = await lendingPool.getUserBorrow(accounts[0], token1.address);

            await lendingPool.borrow(token2.address, token1.address, tokens(0.15).toString(), 1, {from: accounts[0]}).should.be.rejectedWith(EVM_REVERT);
        })
    })
})