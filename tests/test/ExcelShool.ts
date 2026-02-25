import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import hre from "hardhat";

describe("ExcelSchool", function () {
    async function deploySchoolContract() {
        // Contracts are deployed using the first signer/account by default
        const [owner, secondAccount, studentAccount, staffAccount] = await hre.ethers.getSigners();

        const ERC20Contract = await hre.ethers.getContractFactory("ERC20");
        const erc20Contract = await ERC20Contract.deploy(100000000n);

        const SchoolContract = await hre.ethers.getContractFactory("ExcelSchool");
        const schooolContract = await SchoolContract.deploy(erc20Contract.target);
        schooolContract.waitForDeployment();

        return { erc20Contract, owner, schooolContract, secondAccount, studentAccount, staffAccount };
    }


    describe("Student Check", async function () {
        it("Should add a student and claim profile", async function () {
            const { schooolContract, owner, secondAccount, studentAccount, erc20Contract } = await loadFixture(deploySchoolContract)
            //create student profile first, claim faucet and approve and then claim
            const payload = { name: 'Bethel', level: 200, age: 20 }

            //static call to use values
            const student = await schooolContract.addStudent.staticCall(payload.name, payload.level, payload.age)
            expect(student.id).to.equal(0)
            const contractBalanceBefore = await erc20Contract.balanceOf(schooolContract.target)
            console.log("contract bal before", contractBalanceBefore)

            //actuall execution of add student with admin and second account
            await expect(schooolContract.connect(owner).addStudent(payload.name, payload.level, payload.age)).not.to.be.reverted;

            await expect(schooolContract.connect(secondAccount).addStudent(payload.name, payload.level, payload.age)).to.be.revertedWith('Only admin can make this call')

            //claim faucet and approve contract to spend on its behalf
            const faucetAmount = hre.ethers.parseUnits("1000", 18);
            await schooolContract.connect(studentAccount).claimFaucet(studentAccount.address)
            const studentBal = await erc20Contract.balanceOf(studentAccount.address)
            console.log("student's balance before", studentBal)

            expect(studentBal).to.equal(faucetAmount)


            await erc20Contract.connect(studentAccount).approve(schooolContract.target, hre.ethers.parseUnits(student.level.toString(), 18))

            const allowance = await erc20Contract.allowance(studentAccount.address, schooolContract.target)
            console.log('allowance amount', allowance)

            // claim id
            await schooolContract.connect(studentAccount).claimStudentId(student.id);
            const contractBalanceAfter = await erc20Contract.balanceOf(schooolContract.target)
            console.log("contract bal after", contractBalanceAfter)
            const studentBalanceAfter = await erc20Contract.balanceOf(studentAccount.address)
            console.log("student bal after", studentBalanceAfter)

            expect(contractBalanceAfter).to.greaterThan(contractBalanceBefore)
            expect(student.name).to.equal(payload.name);
            expect(student.level).to.equal(payload.level);
            expect(student.age).to.equal(payload.age);

            //return all students
            const studentDetails = await schooolContract.getStudent(studentAccount.address)
            console.log('Student details',studentDetails)
            const allStudents = await schooolContract.getAllStudentDetails()
            expect(allStudents.length).to.greaterThan(0)
        })
    })

    describe("Staff check", async function () {
        it("Create staff,Staff claim ID and Admin Pays staff", async function () {
            const { schooolContract, owner, staffAccount, erc20Contract } = await loadFixture(deploySchoolContract)
            //create staff profile first
            const payload = { name: 'Bethel', salary: 200 }

            //static call to use values
            const staff = await schooolContract.connect(owner).addStaff.staticCall(payload.name, payload.salary);
            expect(staff.id).to.equal(0)

            //actual call to register staff
            await expect(schooolContract.connect(owner).addStaff(payload.name, payload.salary)).not.to.be.reverted;

            await expect(schooolContract.connect(staffAccount).addStaff(payload.name, payload.salary)).to.be.revertedWith('Only admin can make this call')

            //staff to claim id
            await schooolContract.connect(staffAccount).claimStaffId(0)
            const contractBal = await erc20Contract.balanceOf(schooolContract.target)
            console.log("contract bal", contractBal)


            // get staff
            const updatedStaff = await schooolContract.getStaff(staffAccount.address);
            const staffSalary = updatedStaff.salary
            console.log("staff salary", staffSalary)

            expect(contractBal).to.greaterThan(staffSalary);
            // pay staff
            const staffBalBefore = await erc20Contract.balanceOf(staffAccount.address)
            console.log("Staff initial bal", staffBalBefore)
            // console.log("Staff address", staffAccount.address)
            await schooolContract.connect(owner).payStaff(staffAccount.address)
            const staffBalAfter = await erc20Contract.balanceOf(staffAccount.address)
            console.log("Staff final bal", staffBalAfter)
            expect(staffBalAfter).to.greaterThan(0)

            //return all staff
            const allStaff = await schooolContract.getAllStaffDetails()
            expect(allStaff.length).to.greaterThan(0)

        })

    })
});