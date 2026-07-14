import { useEffect, useState } from "react";
import { Route, Routes } from "react-router-dom";

function OrdersPage() {
  const [orders, setOrders] = useState([]);
  useEffect(() => {
    fetch("/api/orders").then((response) => response.json()).then(setOrders);
  }, []);
  return <main><h1>주문 목록</h1>{orders.map((order) => <p key={order.id}>{order.name}</p>)}</main>;
}

export default function App() {
  return <Routes><Route path="/orders" element={<OrdersPage />} /></Routes>;
}
