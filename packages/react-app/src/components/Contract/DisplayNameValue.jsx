/* eslint-disable jsx-a11y/accessible-emoji */
/* eslint-disable jsx-a11y/anchor-is-valid */
import { Col, Divider, Row } from "antd";
import React from "react";
import tryToDisplay from "./utils";

const DisplayNameValue = ({ variableName, variableValue }) => {
  return (
    <div>
      <Row>
        <Col
          span={8}
          style={{
            textAlign: "right",
            opacity: 0.333,
            paddingRight: 6,
            fontSize: 24,
          }}
        >
          {variableName}
        </Col>
        <Col span={14}>
          <h2>{tryToDisplay(variableValue)}</h2>
        </Col>
        <Col span={2}>
          <h2>
            <a href="#">🔄</a>
          </h2>
        </Col>
      </Row>
      <Divider />
    </div>
  );
};

export default DisplayNameValue;
