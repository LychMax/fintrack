export enum TransactionType {
  INCOME = "INCOME",
  EXPENSE = "EXPENSE",
}

export enum Currency {
  BYN = "BYN",
  USD = "USD",
  EUR = "EUR",
  RUB = "RUB",
}

export const CurrencySymbol: Record<Currency, string> = {
  [Currency.BYN]: "Br",
  [Currency.USD]: "$",
  [Currency.EUR]: "€",
  [Currency.RUB]: "₽",
};

export const CurrencyLabel: Record<Currency, string> = {
  [Currency.BYN]: "BYN (Br)",
  [Currency.USD]: "USD ($)",
  [Currency.EUR]: "EUR (€)",
  [Currency.RUB]: "RUB (₽)",
};

export enum PeriodType {
  MONTHLY = "MONTHLY",
  WEEKLY = "WEEKLY",
}

export interface CategoryDto {
  id: number;
  name: string;
}

export interface CategoryCreateDto {
  name: string;
}

export interface TransactionDto {
  id: number;
  amount: number;
  date: string;
  description: string | null;
  type: TransactionType;
  category: CategoryDto;
  currency: Currency;
}

export interface TransactionCreateDto {
  amount: number;
  date: string;
  description?: string | null;
  type: TransactionType;
  categoryId: number;
  currency: Currency;
}

export interface BudgetDto {
  id: number;
  categoryId: number;
  categoryName: string;
  amount: number;
  periodType: PeriodType;
  currency: Currency;
}

export interface BudgetCreateDto {
  categoryId: number;
  amount: number;
  periodType: PeriodType;
  currency: Currency;
}

export interface BudgetStatusDto {
  id: number;
  categoryId: number;
  categoryName: string;
  budgetAmount: number;
  spentAmount: number;
  remainingAmount: number;
  percentUsed: number;
  periodType: PeriodType;
  currency: Currency;
  nearLimit: boolean;
  exceeded: boolean;
}

export interface UserDto {
  id: number;
  username: string;
  email: string;
  mainCurrency: Currency;
  token?: string;
}

export interface CategorySummaryDto {
  categoryName: string;
  totalExpense: number;
  totalIncome: number;
  net: number;
}

export interface DailySummaryDto {
  date: string;
  income: number;
  expense: number;
}

export interface ReportResponse {
  totalIncome: number;
  totalExpense: number;
  balance: number;
  categoryExpenses: CategorySummaryDto[];
  categoryIncomes: CategorySummaryDto[];
  dailySummaries: DailySummaryDto[];
}

export interface JwtResponse {
  token: string;
}

export interface UpdateProfileDto {
  username?: string;
  email?: string;
  mainCurrency?: Currency;
}

export interface ChangePasswordDto {
  oldPassword: string;
  newPassword: string;
}

export interface PageResponse<T> {
  content: T[];
  totalPages: number;
  totalElements: number;
  number: number;
  size: number;
}