import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { Pool } from 'pg';

dotenv.config();

const app = express();
const port = process.env.PORT || 3001;

// Middleware
app.use(cors());
app.use(express.json());

// Database connection (PostgreSQL)
// In a real environment, you'd use a DATABASE_URL from .env
/*
const pool = new Pool({
  connectionString: process.env.DATABASE_URL
});
*/

// --- API Routes ---

app.get('/api/health', (req, res) => {
    res.json({ status: 'ok', message: 'Smart Budget Backend is running' });
});

// Get aggregated dashboard data (from Postgres, not blockchain)
app.get('/api/budget/dashboard/:userAddress', (req, res) => {
    const { userAddress } = req.params;
    
    // Placeholder response simulating what we'd fetch from Postgres
    res.json({
        user: userAddress,
        totalFunds: "5.0", // ETH
        totalSpent: "1.2", // ETH
        categories: [
            { name: "Groceries", limit: "1.0", spent: "0.5" },
            { name: "Rent", limit: "2.0", spent: "0.0" }
        ],
        recentTransactions: [
            { category: "Groceries", amount: "0.5", description: "Whole Foods", date: new Date().toISOString() }
        ]
    });
});

// Update off-chain user settings
app.post('/api/user/settings', (req, res) => {
    const { address, notificationsEnabled, email } = req.body;
    // Save to DB
    res.json({ success: true, message: "Settings updated" });
});

// --- Blockchain Indexer (Simulated) ---
// This would normally be a separate service or background worker

function startIndexer() {
    console.log("Starting Blockchain Indexer...");
    console.log("Listening for SmartBudget events: BudgetCreated, ExpenseRecorded, etc.");
    
    // Here we would use ethers.js to listen to the Smart Contract events
    // and INSERT them into our PostgreSQL database.
    // e.g. contract.on("ExpenseRecorded", (user, category, amount, desc) => { ... })
}

app.listen(port, () => {
    console.log(`Backend API listening on port ${port}`);
    startIndexer();
});
