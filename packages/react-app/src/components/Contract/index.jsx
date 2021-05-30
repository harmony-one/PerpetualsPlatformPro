import { Card } from "antd";
import React, { useMemo, useState } from "react";
import { RadioGroup, RadioButton } from 'react-radio-buttons';
import { Col, Divider, Row, Button, Input } from "antd";
import { useContractExistsAtAddress, useContractLoader } from "../../hooks";
import Account from "../Account";
import DisplayVariable from "./DisplayVariable";
import DisplayNameValue from "./DisplayNameValue";
import FunctionForm from "./FunctionForm";
import { formatEther, parseEther } from "@ethersproject/units";


const noContractDisplay = (
  <div>
    Loading...{" "}
    <div style={{ padding: 32 }}>
      You need to run{" "}
      <span
        className="highlight"
        style={{ marginLeft: 4, /* backgroundColor: "#f1f1f1", */ padding: 4, borderRadius: 4, fontWeight: "bolder" }}
      >
        yarn run chain
      </span>{" "}
      and{" "}
      <span
        className="highlight"
        style={{ marginLeft: 4, /* backgroundColor: "#f1f1f1", */ padding: 4, borderRadius: 4, fontWeight: "bolder" }}
      >
        yarn run deploy
      </span>{" "}
      to see your contract here.
    </div>
    <div style={{ padding: 32 }}>
      <span style={{ marginRight: 4 }} role="img" aria-label="warning">
        ☢️
      </span>
      Warning: You might need to run
      <span
        className="highlight"
        style={{ marginLeft: 4, /* backgroundColor: "#f1f1f1", */ padding: 4, borderRadius: 4, fontWeight: "bolder" }}
      >
        yarn run deploy
      </span>{" "}
      <i>again</i> after the frontend comes up!
    </div>
  </div>
);

const isQueryable = fn => (fn.stateMutability === "view" || fn.stateMutability === "pure") && fn.inputs.length === 0;

export default function Contract({
  customContract,
  account,
  gasPrice,
  signer,
  provider,
  name,
  show,
  price,
  blockExplorer,
  tx,
  writeContracts,
}) {
const [long, setLong] = useState(true);
const [usdc, setUsdc] = useState(0);
const [leverage, setLeverage] = useState(5);

  const contracts = useContractLoader(provider);
  let contract;
  if (!customContract) {
    contract = contracts ? contracts[name] : "";
  } else {
    contract = customContract;
  }

  const address = contract ? contract.address : "";
  const contractIsDeployed = useContractExistsAtAddress(provider, address);

  console.log("%%%%%%%%%%%%%%% contract ", contract);

  const displayedContractFunctions = useMemo(
    () =>
      contract
        ? Object.values(contract.interface.functions).filter(
            fn => fn.type === "function" && !(show && show.indexOf(fn.name) < 0),
          )
        : [],
    [contract, show],
  );

  const [refreshRequired, triggerRefresh] = useState(false);

  // const nameValueArr = [{ variableName: "CurrentPrice", variableValue: "" },
  //   { variableName: "Collateral", variableValue: "" },
  //   { variableName: "Leverage", variableValue: "" },
  // ];

  console.log("^^^^^^^^^^displayedContractFunctions", displayedContractFunctions);

  // const contractDisplay = nameValueArr.map(({ variableName, variableValue }) => {
  //   return <DisplayNameValue variableName={variableName} variableValue={variableValue} />;
  // });
  let contractDisplay = displayedContractFunctions.map(fn => {
    if (isQueryable(fn)) {
      // If there are no inputs, just display return value
      if (fn.name === "getXAUPrice" || fn.name === "leverage"  || fn.name === "getvUSDCreserve"
       || fn.name === "getvXAUreserve" || fn.name === "getvXAUlong") {
        let contractFnName = "";
        // eslint-disable-next-line default-case
        switch(fn.name){
          case "getXAUPrice":
            contractFnName= "Current Price (XAU)";
            break;
          case "leverage":
            contractFnName="Leverage"
            break;
          case "getvUSDCreserve":
            contractFnName= "USDC Reserve";
            break;
          case "getvXAUreserve":
            contractFnName= "XAU Reserve";
            break;
          case "getvXAUlong":
            contractFnName= "vXAU Amount";
            break;
        }
        return (
          <DisplayVariable
            key={fn.name}
            contractFunction={contract[fn.name]}
            contractFunctionName={contractFnName}
            functionInfo={fn}
            refreshRequired={refreshRequired}
            triggerRefresh={triggerRefresh}
          />
        );
      }
    }

    // If there are inputs, display a form to allow users to provide these
    if (fn.name === "USDCvault") {
      // if (fn.name === "leverage" || fn.name === "USDCvault") {
        return (
        <FunctionForm
          key={"FF" + fn.name}
          contractFunction={
            fn.stateMutability === "view" || fn.stateMutability === "pure"
              ? contract[fn.name]
              : contract.connect(signer)[fn.name]
          }
          functionInfo={fn}
          provider={provider}
          gasPrice={gasPrice}
          triggerRefresh={triggerRefresh}
        />
      );
    }
    if (fn.name === "withdraw") {
      return (
        <>
        {/* <div style={{ padding: 32 }}>
          <Row>
              <Col span={9} style={{ textAlign: "center", opacity: 1 }}>
            USDC
          </Col>
          <Col span={9} style={{ textAlign: "center", opacity: 1 }}>
                <Input size="large" autoComplete="off" value={usdc} name="USDC" />
          </Col>
          </Row>
        </div>
        <div style={{ padding: 32 }}>
        <Row>
              <Col span={9} style={{ textAlign: "center", opacity: 1 }}>
            USDC
          </Col>
          <Col span={9} style={{ textAlign: "center", opacity: 1 }}>
                <Input size="large" autoComplete="off" value={leverage} name="Leverage" />
          </Col>
          </Row>
        </div> */}
        {/* <div style={{ padding: 32 }}>
        <Row>
          <Col span={9} style={{ textAlign: "center", opacity: 1 }}>
                VXAU Amount
          </Col>
          <Col span={9} style={{ textAlign: "center", opacity: 1 }}>
            {contract}
          </Col>
        </Row>
        </div> */}
        <div style={{ padding: 32 }}>
        <Row>
            <RadioGroup horizontal onChange={event => setLong(event)}>
              <RadioButton value="true">Long</RadioButton>
              <RadioButton value="false">Short</RadioButton>
            </RadioGroup>
        </Row>
        </div>
      </>
      );
    }
  });
  contractDisplay = contractDisplay.filter(item => item !== undefined);
  contractDisplay = [ ...contractDisplay,
    <div style={{ padding: 32 }}>
      <Row align="middle">
        <Col span={8} style={{ textAlign: "center", opacity: 1 }} />
        <Col span={8} style={{ textAlign: "center", opacity: 1 }}>
          <Button
            onClick={async () => {
              if (long) {
                console.log("*** in LONG");
                // tx(writeContracts.Perpetual.leverage(3));
                // await tx(writeContracts.Perpetual.deposit(1000));
                await tx(writeContracts.Perpetual.MintLongXAU(parseEther("10")));
              } else {
                console.log("*** in Short");
                tx(writeContracts.Perpetual.leverage(3));
                // tx(writeContracts.Perpetual.MintShortXAU(100));
              }
            }}
            size="large"
            shape="round"
          >
            <span style={{ marginRight: 8 }} role="img" aria-label="Submit" />
            Submit
          </Button>
        </Col>
      </Row>
    </div>,
  ];

  console.log(" ######################## contractDisplay ", contractDisplay);

  return (
    <div style={{ margin: "auto", width: "70vw" }}>
      <Card
        title={
          <div>
            {name}
            <div style={{ float: "right" }}>
              <Account
                address={address}
                localProvider={provider}
                injectedProvider={provider}
                mainnetProvider={provider}
                price={price}
                blockExplorer={blockExplorer}
              />
              {account}
            </div>
          </div>
        }
        size="large"
        style={{ marginTop: 25, width: "100%" }}
        loading={contractDisplay && contractDisplay.length <= 0}
      >
        {contractIsDeployed ? contractDisplay : noContractDisplay}
      </Card>
    </div>
  );
}
