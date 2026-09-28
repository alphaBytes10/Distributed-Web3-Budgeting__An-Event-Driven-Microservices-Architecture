// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract SmartBudget {
    
    struct Category {
        string name;
        uint256 limit;
        uint256 spent;
    }

    struct Budget {
        uint256 totalFunds;
        uint256 totalSpent;
        mapping(string => Category) categories;
        string[] categoryNames;
        bool exists;
    }

    // Mapping from user address to their Budget
    mapping(address => Budget) public budgets;

    // --- Events (Crucial for the Indexer/Backend) ---
    event BudgetCreated(address indexed user, uint256 initialFunds);
    event FundsAdded(address indexed user, uint256 amount, uint256 newTotal);
    event CategoryLimitSet(address indexed user, string category, uint256 limit);
    event ExpenseRecorded(address indexed user, string category, uint256 amount, string description);

    // --- Modifiers ---
    modifier budgetExists() {
        require(budgets[msg.sender].exists, "Budget does not exist. Create one first.");
        _;
    }

    // --- Core Functions ---

    /**
     * @dev Initializes a budget for the user. They can send ETH to fund it.
     */
    function createBudget() external payable {
        require(!budgets[msg.sender].exists, "Budget already exists.");
        
        Budget storage newBudget = budgets[msg.sender];
        newBudget.totalFunds = msg.value;
        newBudget.totalSpent = 0;
        newBudget.exists = true;

        emit BudgetCreated(msg.sender, msg.value);
    }

    /**
     * @dev Add more funds to an existing budget.
     */
    function addFunds() external payable budgetExists {
        require(msg.value > 0, "Must send ETH to add funds.");
        
        budgets[msg.sender].totalFunds += msg.value;
        emit FundsAdded(msg.sender, msg.value, budgets[msg.sender].totalFunds);
    }

    /**
     * @dev Sets or updates a spending limit for a specific category.
     */
    function setCategoryLimit(string memory _category, uint256 _limit) external budgetExists {
        Budget storage userBudget = budgets[msg.sender];
        
        if (userBudget.categories[_category].limit == 0 && userBudget.categories[_category].spent == 0) {
            // New category
            userBudget.categoryNames.push(_category);
            userBudget.categories[_category].name = _category;
        }
        
        userBudget.categories[_category].limit = _limit;
        emit CategoryLimitSet(msg.sender, _category, _limit);
    }

    /**
     * @dev Records an expense. Rejects if over total funds or over category limit.
     */
    function recordExpense(string memory _category, uint256 _amount, string memory _description) external budgetExists {
        Budget storage userBudget = budgets[msg.sender];
        
        require(_amount > 0, "Expense amount must be greater than 0");
        require(userBudget.totalFunds >= userBudget.totalSpent + _amount, "Insufficient total funds");
        
        Category storage category = userBudget.categories[_category];
        
        // If category has a limit, enforce it (0 means no limit set for that specific category, just total funds limit)
        if (category.limit > 0) {
            require(category.spent + _amount <= category.limit, "Category limit exceeded");
        }
        
        category.spent += _amount;
        userBudget.totalSpent += _amount;
        
        emit ExpenseRecorded(msg.sender, _category, _amount, _description);
    }

    // --- View Functions ---

    /**
     * @dev Returns total funds and total spent for the caller.
     */
    function getBudgetOverview() external view budgetExists returns (uint256 totalFunds, uint256 totalSpent, uint256 remaining) {
        Budget storage userBudget = budgets[msg.sender];
        return (userBudget.totalFunds, userBudget.totalSpent, userBudget.totalFunds - userBudget.totalSpent);
    }

    /**
     * @dev Returns details for a specific category.
     */
    function getCategoryDetails(string memory _category) external view budgetExists returns (uint256 limit, uint256 spent, uint256 remaining) {
        Category storage category = budgets[msg.sender].categories[_category];
        uint256 _remaining = 0;
        if (category.limit > category.spent) {
            _remaining = category.limit - category.spent;
        }
        return (category.limit, category.spent, _remaining);
    }
}
