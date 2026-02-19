// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;
import "./Events.sol";

contract ExcelSchool {
    //handle staff
    address admin;

    mapping(uint8 => uint256) public levelPrice;
    mapping(address => Roles) userRoles;

    constructor() {
        admin = msg.sender;
        levelPrice[1] = 0.014 ether;
        levelPrice[2] = 0.025 ether;
        levelPrice[3] = 0.05 ether;
        levelPrice[4] = 0.09 ether;
        userRoles[admin] = Roles.admin;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can make this call");
        _;
    }

    enum Roles {
        admin,
        staff,
        student
    }

    enum Status {
        unpaid,
        paid
    }

    struct Staff {
        uint id;
        string name;
        address wallet;
        uint salary;
        bool paid;
        uint paidAt;
        Roles role;
        bool claimed;
        uint claimedAt;
    }

    struct Student {
        uint id;
        string name;
        address wallet;
        uint8 level;
        uint8 age;
        uint amountPaid;
        Status paymentStatus;
        Roles role;
        bool claimed;
        uint claimedAt;
    }

    //student modifier
    modifier onlyStudent(Roles _role) {
        require(_role == Roles.student, "Only student");
        _;
    }
    // staff modifiers
    modifier onlyStaff(Roles _role) {
        require(_role == Roles.staff, "Only staff");
        _;
    }

    //mappings
    mapping(address => Student) public studentDetails;
    mapping(address => uint256) lastPaid;
    uint256 public schoolTreasury;
    uint256 constant PAY_INTERVAL = 30 days;
    mapping(address => Staff) public staffDetails;
    mapping(address => uint256) public schoolAccount;

    //check if paid recently modifier
    modifier checkIfStaffIsPaidRecently(address _staff_wallet) {
        require(
            staffDetails[_staff_wallet].role == Roles.staff,
            "Only staff are paid"
        );
        uint _now = block.timestamp;
        uint last = lastPaid[_staff_wallet];
        require(_now < last + PAY_INTERVAL, "Paid recently");
        _;
    }

    Staff[] public staffList;
    Student[] public studentList;

    function addStudent(
        string memory _name,
        uint8 _level,
        uint8 _age
    ) public onlyAdmin {
        require(_level > 0 && _level <= 4, "Level Exceeded");
        uint index = studentList.length;
        Student memory newStudent = Student({
            id: index,
            name: _name,
            wallet: address(0),
            level: _level,
            age: _age,
            amountPaid: 0,
            paymentStatus: Status.unpaid,
            role: Roles.student,
            claimed: false,
            claimedAt: 0
        });
        studentList.push(newStudent);
        emit Events.StudentEvent("student added sucessfully", newStudent.id);
    }

    function addStaff(string memory _name, uint _salary) public onlyAdmin {
        uint _id = staffList.length;
        Staff memory newStaff = Staff({
            id: _id,
            name: _name,
            wallet: address(0),
            salary: _salary,
            paid: false,
            paidAt: 0,
            role: Roles.staff,
            claimed: false,
            claimedAt: 0
        });
        staffList.push(newStaff);
        emit Events.StaffEvent(newStaff.id, newStaff.wallet);
    }

    function claimStaffId(uint _Id) external {
        require(_Id < staffList.length, "Staff not found");

        Staff storage unClaimedStaff = staffList[_Id];

        require(!unClaimedStaff.claimed, "Already claimed");

        unClaimedStaff.wallet = msg.sender;
        unClaimedStaff.claimed = true;
        unClaimedStaff.claimedAt = block.timestamp;
        staffDetails[unClaimedStaff.wallet];
        userRoles[msg.sender] = Roles.staff;

        emit Events.StaffEvent(_Id, unClaimedStaff.wallet);
    }

    function claimStudentId(
        uint _Id
    ) external payable onlyStudent(Roles.student) {
        require(_Id < studentList.length, "Student not found");

        Student storage student = studentList[_Id];

        require(!student.claimed, "Already claimed");

        uint fee = levelPrice[student.level];
        require(fee > 0, "Invalid level");
        require(msg.value == fee, "Wrong amount");

        schoolTreasury = schoolTreasury + msg.value;
        student.wallet = msg.sender;

        student.amountPaid = msg.value;

        student.claimed = true;
        student.claimedAt = block.timestamp;
        student.paymentStatus = Status.paid;
        studentDetails[student.wallet];
        userRoles[msg.sender] = Roles.student;

        emit Events.StudentClaimEvent(_Id, msg.value, student.wallet);
    }

    function payStaff(
        address _wallet
    ) external onlyAdmin checkIfStaffIsPaidRecently(_wallet) {
        Staff storage _staff = staffDetails[_wallet];
        require(
            _staff.wallet != address(0),
            "Not staff/Unclaimed staff profile"
        );
        require(_staff.salary > 0, "Salary can't be 0 ether");
        require(
            schoolTreasury >= _staff.salary,
            "Insufficient funds in treasury"
        );
        schoolTreasury -= _staff.salary;
        lastPaid[_wallet] = block.timestamp;
        _staff.paid = true;
        _staff.paidAt = block.timestamp;
        (bool success, ) = payable(_wallet).call{value: _staff.salary}("");
        require(success);
    }

    function getStudent(address _wallet) public view returns (Student memory) {
        return studentDetails[_wallet];
    }

    function getStaff(address _wallet) public view returns (Staff memory) {
        return staffDetails[_wallet];
    }

    function getAllStaff() public view returns (Staff[] memory) {
        Staff[] memory allStaff = new Staff[](staffList.length);

        for (uint i = 0; i < staffList.length; i++) {
            allStaff[i] = staffDetails[staffList[i].wallet];
        }

        return allStaff;
    }

    function getAllstudentList() public view returns (Student[] memory) {
         Student[] memory allStudents = new Student[](studentList.length);

        for (uint i = 0; i < studentList.length; i++) {
            allStudents[i] = studentDetails[studentList[i].wallet];
        }

        return allStudents;
    }

    receive() external payable {}
}
