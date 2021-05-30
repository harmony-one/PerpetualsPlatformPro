import { PageHeader } from "antd";
import React from "react";
import ppp from "./../views/img/logo192.png"


// displays a page header

export default function Header() {
  return (
    <a href="https://github.com/austintgriffith/scaffold-eth" target="_blank" rel="noopener noreferrer">
      <img src={ppp} alt="" width="120" height="70" align="left" style={{ padding: 16 }} />
      <PageHeader title="" subTitle="  Trading futures" style={{ cursor: "pointer" }} />
    </a>
  );
}
